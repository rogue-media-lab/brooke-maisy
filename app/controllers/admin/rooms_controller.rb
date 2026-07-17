class Admin::RoomsController < Admin::BaseController
  before_action :set_project, only: [ :index, :new, :create ]
  before_action :set_room, only: [ :show, :edit, :update, :destroy ]

  def index
    @rooms = @project.rooms.ordered
  end

  def show
  end

  def new
    @room = @project.rooms.new
  end

  def create
    @room = @project.rooms.new(room_params)
    if @room.save
      redirect_to admin_project_room_path(@project, @room), notice: "Room added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @project = @room.project
  end

  def update
    @project = @room.project
    if @room.update(room_params)
      redirect_to admin_project_room_path(@room.project, @room), notice: "Room updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project = @room.project
    @room.destroy
    redirect_to admin_project_rooms_path(project), notice: "Room removed."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:name, :position, :notes)
  end
end
