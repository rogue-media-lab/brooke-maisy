class Admin::DashboardController < Admin::BaseController
  def index
    @client_count       = Client.count
    @project_count      = Project.count
    @active_count       = Project.where.not(status: "complete").count
    @complete_count     = Project.where(status: "complete").count
    @unread_messages    = Message.unread.count
    @unread_questionnaires = QuestionnaireSubmission.unread.count
    @recent_projects    = Project.includes(:client).recent.limit(6)
    @recent_updates     = ProjectUpdate.includes(:project).recent.limit(5)
    @status_breakdown   = Project.group(:status).count
    @quote_count        = Quote.live.count
    @recent_quotes      = Quote.live.includes(:client, :project).recent.limit(5)
  end
end
