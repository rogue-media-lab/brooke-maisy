class Admin::PublicationsController < Admin::BaseController
  before_action :set_presentation

  def create
    if @presentation.draft?
      @presentation.update!(status: "published", published_at: Time.current)
    end
    redirect_to admin_project_design_presentation_path(@project, @presentation), notice: "Presentation published."
  end

  def destroy
    if @presentation.published?
      @presentation.update!(status: "draft", published_at: nil)
    end
    redirect_to admin_project_design_presentation_path(@project, @presentation), notice: "Presentation unpublished."
  end

  private

  def set_presentation
    @project = Project.find(params[:project_id])
    @presentation = @project.design_presentations.find(params[:design_presentation_id])
  end
end
