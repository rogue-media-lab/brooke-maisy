class Admin::ProjectUpdatesController < Admin::BaseController
  before_action :set_project

  def create
    @update = @project.project_updates.build(update_params)
    if @update.save
      redirect_to admin_project_path(@project), notice: "Update posted."
    else
      redirect_to admin_project_path(@project), alert: "Update could not be saved (body required)."
    end
  end

  def destroy
    @update = @project.project_updates.find(params[:id])
    @update.destroy
    redirect_to admin_project_path(@project), notice: "Update removed."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def update_params
    params.require(:project_update).permit(:body, :visible_to_client)
  end
end
