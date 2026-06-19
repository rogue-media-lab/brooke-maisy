module QuestionnaireSubmissionsHelper
  def questionnaire_value(section, key)
    value_at(questionnaire_answers, section, key)
  end

  def questionnaire_checked?(section, key, value)
    Array(questionnaire_value(section, key)).include?(value.to_s)
  end

  def questionnaire_radio?(section, key, value)
    questionnaire_value(section, key) == value.to_s
  end

  def questionnaire_rooms
    raw = questionnaire_answers["rooms"]

    case raw
    when Array then raw.select { |room| room.is_a?(Hash) }
    when Hash  then raw.values.select { |room| room.is_a?(Hash) }
    else []
    end
  end

  def questionnaire_room_value(room, key)
    room[key.to_s]
  end

  def questionnaire_room_checked?(room, key, value)
    Array(questionnaire_room_value(room, key)).include?(value.to_s)
  end

  def questionnaire_room_radio?(room, key, value)
    questionnaire_room_value(room, key) == value.to_s
  end

  def questionnaire_display_value(section, key)
    format_questionnaire_value(questionnaire_value(section, key))
  end

  def questionnaire_room_display_value(room, key)
    format_questionnaire_value(questionnaire_room_value(room, key))
  end

  # Renders a titled card with a label/value grid. Used by the review summary.
  def render_section_summary(title, rows)
    content_tag(:div, class: "rounded-xl border border-theme-100 bg-theme-50 p-5") do
      heading = content_tag(:h3, title, class: "font-serif text-xl font-semibold text-theme-500 mb-4")
      grid = content_tag(:dl, class: "grid md:grid-cols-2 gap-4 text-sm") do
        safe_join(rows.map do |label, value|
          content_tag(:div) do
            content_tag(:dt, label, class: "text-xs font-semibold uppercase tracking-wider text-gray-400") +
              content_tag(:dd, value, class: "text-gray-700 mt-1 whitespace-pre-wrap")
          end
        end)
      end
      heading + grid
    end
  end

  private

  def questionnaire_answers
    @submission.answers || {}
  end

  def value_at(hash, *keys)
    keys.reduce(hash) do |current, key|
      if current.is_a?(Array)
        return nil if key.to_i >= current.length

        return current[key.to_i]
      end

      return nil unless current.is_a?(Hash)

      current[key.to_s]
    end
  end

  def format_questionnaire_value(value)
    case value
    when Array
      formatted = value.compact_blank.join(", ")
      formatted.presence || "—"
    when Hash
      formatted = value.compact_blank.map { |key, nested_value| "#{key}: #{format_questionnaire_value(nested_value)}" }
      formatted.join("; ").presence || "—"
    else
      value.presence || "—"
    end
  end
end
