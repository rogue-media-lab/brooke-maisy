class Admin::ColorSwatchesController < Admin::BaseController
  before_action :set_presentation
  before_action :set_color_swatch, only: [ :show, :edit, :update, :destroy, :move ]

  def index
    @color_swatches = @presentation.color_swatches.ordered
  end

  def show
    render nothing: true
  end

  def new
    @color_swatch = @presentation.color_swatches.build
  end

  def create
    @color_swatch = @presentation.color_swatches.build(color_swatch_params)
    if @color_swatch.save
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
    if @color_swatch.update(color_swatch_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @color_swatch.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
    end
  end

  def move
    direction = params[:direction]
    if direction == "up"
      neighbor = @presentation.color_swatches.where("position < ?", @color_swatch.position).order(position: :desc).first
    elsif direction == "down"
      neighbor = @presentation.color_swatches.where("position > ?", @color_swatch.position).order(position: :asc).first
    end
    if neighbor
      @color_swatch.position, neighbor.position = neighbor.position, @color_swatch.position
      @color_swatch.save!
      neighbor.save!
    end
    redirect_to admin_project_design_presentation_path(@project, @presentation)
  end

  private

  def set_presentation
    @project = Project.find(params[:project_id])
    @presentation = @project.design_presentations.find(params[:design_presentation_id])
  end

  def set_color_swatch
    @color_swatch = @presentation.color_swatches.find(params[:id])
  end

  def color_swatch_params
    params.require(:color_swatch).permit(:name, :hex_code, :brand, :finish, :room, :position)
  end
end
