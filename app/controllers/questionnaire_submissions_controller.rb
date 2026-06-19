class QuestionnaireSubmissionsController < ApplicationController
  STEP_TITLES = [
    "Contact & Lifestyle",
    "Home & Project Intent",
    "Function & Priorities",
    "Design Direction",
    "Rooms, Budget & Logistics",
    "Review"
  ].freeze

  DRAFT_SESSION_KEY = :questionnaire_draft_id

  def new
    @submission = current_draft
    @current_step = normalized_step(params[:current_step] || params[:step])
  end

  def create
    @submission = current_draft
    apply_incoming_answers

    if params.key?(:next_step)
      persist_draft
      @current_step = normalized_step(params[:current_step].to_i + 1)
      render :new, status: :unprocessable_entity
    elsif params.key?(:previous_step)
      persist_draft
      @current_step = normalized_step(params[:current_step].to_i - 1)
      render :new, status: :unprocessable_entity
    elsif finalize_submission
      clear_draft_session
      redirect_to contact_path, notice: "Thank you. Your client questionnaire has been submitted."
    else
      persist_draft
      @current_step = @submission.missing_step || STEP_TITLES.length
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Find the in-progress draft for this browser session, or build a fresh one.
  # Only the draft's id lives in the cookie, so the session payload stays tiny.
  def current_draft
    if session[DRAFT_SESSION_KEY].present?
      QuestionnaireSubmission.drafts.find_by(id: session[DRAFT_SESSION_KEY]) ||
        QuestionnaireSubmission.new(status: QuestionnaireSubmission::DRAFT)
    else
      QuestionnaireSubmission.new(status: QuestionnaireSubmission::DRAFT)
    end
  end

  # Merge the just-submitted step into the draft's accumulated answers.
  # The final review step posts no questionnaire fields, so tolerate their absence.
  def apply_incoming_answers
    return if questionnaire_submission_params.blank?

    incoming = questionnaire_submission_params.to_h
    incoming_answers = incoming.delete("answers") || {}
    merged_answers = (@submission.answers || {}).deep_merge(incoming_answers)

    @submission.assign_attributes(incoming.merge("answers" => merged_answers))
  end

  # Save the draft (skipping completeness validations) and remember its id.
  def persist_draft
    @submission.status = QuestionnaireSubmission::DRAFT
    @submission.save(validate: false)
    session[DRAFT_SESSION_KEY] = @submission.id
  end

  # Promote the draft to a completed submission, running full validations.
  def finalize_submission
    @submission.status = QuestionnaireSubmission::COMPLETED
    return true if @submission.save

    # Roll back to draft so a failed final submit can still persist progress.
    @submission.status = QuestionnaireSubmission::DRAFT
    false
  end

  def clear_draft_session
    session.delete(DRAFT_SESSION_KEY)
  end

  def normalized_step(value)
    value.to_i.clamp(1, STEP_TITLES.length)
  end

  def questionnaire_submission_params
    return ActionController::Parameters.new.permit! if params[:questionnaire_submission].blank?

    params.require(:questionnaire_submission).permit(
      :name,
      :email,
      :phone,
      :preferred_contact,
      answers: {}
    ).tap do |permitted|
      permitted[:answers] = stringify_questionnaire_values(permitted[:answers])
    end
  end

  def stringify_questionnaire_values(value)
    case value
    when ActionController::Parameters
      value.to_unsafe_h.transform_values { |nested_value| stringify_questionnaire_values(nested_value) }
    when Hash
      value.transform_keys(&:to_s).transform_values { |nested_value| stringify_questionnaire_values(nested_value) }
    when Array
      value.map { |nested_value| stringify_questionnaire_values(nested_value) }
    else
      value
    end
  end
end
