class Admin::DashboardController < Admin::BaseController
  def index
    @client_count       = User.where(role: "client").count
    @project_count      = Project.count
    @active_count       = Project.where.not(status: "complete").count
    @complete_count     = Project.where(status: "complete").count
    @unread_messages    = Message.unread.count
    @recent_projects    = Project.includes(:user).recent.limit(6)
    @recent_updates     = ProjectUpdate.includes(:project).recent.limit(5)
    @status_breakdown   = Project.group(:status).count
  end
end
