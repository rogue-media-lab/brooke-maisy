class Tech::DashboardController < Tech::BaseController
  def show
    authorize :dashboard, policy_class: Tech::DashboardPolicy
    @projects = Project.order(updated_at: :desc).limit(20)
    @project = if params[:project_id]
                 Project.find(params[:project_id])
    else
                 @projects.first
    end
    @checklist_items = ChecklistItem.active
  end
end
