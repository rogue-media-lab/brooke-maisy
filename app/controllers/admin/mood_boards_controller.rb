class Admin::MoodBoardsController < Admin::BaseController
  before_action :set_presentation
  before_action :set_mood_board, only: [ :show, :edit, :update, :destroy, :move ]

  def index
    @mood_boards = @presentation.mood_boards.ordered
  end

  def show
    render nothing: true
  end

  def new
    @mood_board = @presentation.mood_boards.build
  end

  def create
    @mood_board = @presentation.mood_boards.build(mood_board_params)
    if @mood_board.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @mood_board.update(mood_board_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @mood_board.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
    end
  end

  def move
    direction = params[:direction]
    if direction == "up"
      neighbor = @presentation.mood_boards.where("position < ?", @mood_board.position).order(position: :desc).first
    elsif direction == "down"
      neighbor = @presentation.mood_boards.where("position > ?", @mood_board.position).order(position: :asc).first
    end
    if neighbor
      @mood_board.position, neighbor.position = neighbor.position, @mood_board.position
      @mood_board.save!
      neighbor.save!
    end
    redirect_to admin_project_design_presentation_path(@project, @presentation)
  end

  private

  def set_presentation
    @project = Project.find(params[:project_id])
    @presentation = @project.design_presentations.find(params[:design_presentation_id])
  end

  def set_mood_board
    @mood_board = @presentation.mood_boards.find(params[:id])
  end

  def mood_board_params
    params.require(:mood_board).permit(:name, :position)
  end
end
