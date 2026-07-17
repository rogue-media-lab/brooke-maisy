class Admin::WindowsController < Admin::BaseController
  before_action :set_room, only: [ :index, :new, :create ]
  before_action :set_window, only: [ :show, :edit, :update, :destroy ]

  def index
    @windows = @room.windows.ordered
  end

  def show
  end

  def new
    @window = @room.windows.new
  end

  def create
    @window = @room.windows.new(window_params)
    if @window.save
      redirect_to admin_room_window_path(@room, @window), notice: "Window added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @window.update(window_params)
      redirect_to admin_room_window_path(@window.room, @window), notice: "Window updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    room = @window.room
    @window.destroy
    redirect_to admin_room_windows_path(room), notice: "Window removed."
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_window
    @window = Window.find(params[:id])
  end

  def window_params
    params.require(:window).permit(:name, :width, :height, :mount_type, :depth, :notes, :position, :photo)
  end
end
