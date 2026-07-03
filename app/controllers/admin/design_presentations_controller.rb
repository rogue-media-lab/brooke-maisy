class Admin::DesignPresentationsController < Admin::BaseController
  before_action :set_project
  before_action :set_presentation, only: [ :show, :edit, :update, :destroy ]

  def index
    @presentations = @project.design_presentations.ordered
  end

  def show
    @mood_boards = @presentation.mood_boards.ordered
    @product_selections = @presentation.product_selections.ordered
    @color_swatches = @presentation.color_swatches.ordered
  end

  def new
    @presentation = @project.design_presentations.build
  end

  def create
    @presentation = @project.design_presentations.build(presentation_params)
    if @presentation.save
      redirect_to admin_project_design_presentation_path(@project, @presentation), notice: "Presentation created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @presentation.update(presentation_params)
      redirect_to admin_project_design_presentation_path(@project, @presentation), notice: "Presentation updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @presentation.destroy
    redirect_to admin_project_path(@project), notice: "Presentation deleted."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_presentation
    @presentation = @project.design_presentations.find(params[:id])
  end

  def presentation_params
    params.require(:design_presentation).permit(:title, :position)
  end
end
