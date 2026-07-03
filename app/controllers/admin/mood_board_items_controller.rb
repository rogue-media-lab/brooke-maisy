class Admin::MoodBoardItemsController < Admin::BaseController
  before_action :set_mood_board
  before_action :set_item, only: [ :show, :edit, :update, :destroy, :move ]

  def index
    @items = @mood_board.mood_board_items.ordered
  end

  def show
    render nothing: true
  end

  def new
    @item = @mood_board.mood_board_items.build
  end

  def create
    @item = @mood_board.mood_board_items.build(item_params)
    if @item.save
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
    if @item.update(item_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
    end
  end

  def move
    direction = params[:direction]
    if direction == "up"
      neighbor = @mood_board.mood_board_items.where("position < ?", @item.position).order(position: :desc).first
    elsif direction == "down"
      neighbor = @mood_board.mood_board_items.where("position > ?", @item.position).order(position: :asc).first
    end
    if neighbor
      @item.position, neighbor.position = neighbor.position, @item.position
      @item.save!
      neighbor.save!
    end
    redirect_to admin_project_design_presentation_path(@project, @presentation)
  end

  private

  def set_mood_board
    @project = Project.find(params[:project_id])
    @presentation = @project.design_presentations.find(params[:design_presentation_id])
    @mood_board = @presentation.mood_boards.find(params[:mood_board_id])
  end

  def set_item
    @item = @mood_board.mood_board_items.find(params[:id])
  end

  def item_params
    params.require(:mood_board_item).permit(:caption, :category, :position, :image)
  end
end
