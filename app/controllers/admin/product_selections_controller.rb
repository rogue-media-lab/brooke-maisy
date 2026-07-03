class Admin::ProductSelectionsController < Admin::BaseController
  before_action :set_presentation
  before_action :set_product_selection, only: [ :show, :edit, :update, :destroy, :move ]

  def index
    @product_selections = @presentation.product_selections.ordered
  end

  def show
    render nothing: true
  end

  def new
    @product_selection = @presentation.product_selections.build
  end

  def create
    @product_selection = @presentation.product_selections.build(product_selection_params)
    if @product_selection.save
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
    if @product_selection.update(product_selection_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product_selection.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_project_design_presentation_path(@project, @presentation) }
    end
  end

  def move
    direction = params[:direction]
    if direction == "up"
      neighbor = @presentation.product_selections.where("position < ?", @product_selection.position).order(position: :desc).first
    elsif direction == "down"
      neighbor = @presentation.product_selections.where("position > ?", @product_selection.position).order(position: :asc).first
    end
    if neighbor
      @product_selection.position, neighbor.position = neighbor.position, @product_selection.position
      @product_selection.save!
      neighbor.save!
    end
    redirect_to admin_project_design_presentation_path(@project, @presentation)
  end

  private

  def set_presentation
    @project = Project.find(params[:project_id])
    @presentation = @project.design_presentations.find(params[:design_presentation_id])
  end

  def set_product_selection
    @product_selection = @presentation.product_selections.find(params[:id])
  end

  def product_selection_params
    params.require(:product_selection).permit(:name, :description, :vendor, :price, :product_url, :room, :status, :client_notes, :position, :quantity, :image)
  end
end
