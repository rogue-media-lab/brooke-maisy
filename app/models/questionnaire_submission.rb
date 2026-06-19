class QuestionnaireSubmission < ApplicationRecord
  DRAFT = "draft".freeze
  COMPLETED = "completed".freeze
  STATUSES = [ DRAFT, COMPLETED ].freeze

  # Completeness validations only apply to a final, completed submission.
  # Drafts are allowed to save incomplete so multi-step progress can persist.
  validates :name, presence: true, if: :completed?
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :completed?
  validates :answers, presence: true, if: :completed?
  validate :questionnaire_answers_are_complete, if: :completed?

  validates :status, inclusion: { in: STATUSES }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :drafts, -> { where(status: DRAFT) }

  def draft?
    status == DRAFT
  end

  def completed?
    status == COMPLETED
  end

  def missing_step
    return 1 if name.blank? || email.blank? || preferred_contact.blank?
    return 1 unless present_array?(answers_section("household"), "members")

    return 2 unless present_array?(answers_section("home"), "spaces")
    return 2 unless present_array?(answers_section("home"), "project_types")

    return 4 unless present_array?(answers_section("design"), "style_direction")

    return 5 unless rooms.any?
    return 5 unless present_scalar?(answers_section("budget"), "approach")
    return 5 unless present_scalar?(answers_section("logistics"), "living_during_project")

    nil
  end

  private

  def questionnaire_answers_are_complete
    return if answers.blank?

    errors.add(:answers, "Please select at least one household member.") if missing_step == 1
    return if errors.any?

    errors.add(:answers, "Please select the spaces included in the project.") if missing_step == 2
    errors.add(:answers, "Please select at least one project type.") if missing_step == 2
    return if errors.any?

    errors.add(:answers, "Please choose up to three style directions.") if missing_step == 4
    return if errors.any?

    errors.add(:answers, "Please add at least one room.") if missing_step == 5
    errors.add(:answers, "Please choose a budget approach.") if missing_step == 5
    errors.add(:answers, "Please tell us whether you will be living in the home during the project.") if missing_step == 5
  end

  def answers_section(name)
    (answers || {})[name.to_s] || {}
  end

  def present_array?(section, key)
    Array(section[key.to_s]).any?(&:present?)
  end

  def present_scalar?(section, key)
    section[key.to_s].present?
  end

  def rooms
    raw = (answers || {})["rooms"]
    candidates =
      case raw
      when Array then raw
      when Hash  then raw.values
      else []
      end

    candidates.select { |room| room.is_a?(Hash) && room.values.any?(&:present?) }
  end
end
