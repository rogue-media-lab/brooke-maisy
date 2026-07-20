# frozen_string_literal: true

class Clients::QuotePolicy < ApplicationPolicy
  # Client can only view quotes assigned to them that have been sent
  def show?
    return false unless user

    user.admin? || (
      record.client_id == user.client_id &&
      !record.draft? &&
      !record.is_template?
    )
  end

  def approve?
    show? && record.sent? || record.viewed?
  end

  def approve_line_item?
    show?
  end

  def decline_line_item?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.client_visible
      else
        scope.client_visible.where(client_id: user.client_id)
      end
    end
  end
end
