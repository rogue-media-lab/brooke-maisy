class Admin::QuestionnaireSubmissionsController < Admin::BaseController
  STATUS_FILTERS = %w[all completed drafts].freeze

  def index
    @status_filter = STATUS_FILTERS.include?(params[:status]) ? params[:status] : "completed"

    @submissions =
      case @status_filter
      when "drafts"    then QuestionnaireSubmission.drafts.recent
      when "all"       then QuestionnaireSubmission.recent
      else                  QuestionnaireSubmission.completed.recent
      end

    @completed_count = QuestionnaireSubmission.completed.count
    @draft_count = QuestionnaireSubmission.drafts.count
  end

  def show
    @submission = QuestionnaireSubmission.find(params[:id])
    @submission.update_column(:read, true) unless @submission.read?
  end

  def destroy
    @submission = QuestionnaireSubmission.find(params[:id])
    @submission.destroy
    redirect_to admin_questionnaire_submissions_path, notice: "Questionnaire deleted."
  end
end
