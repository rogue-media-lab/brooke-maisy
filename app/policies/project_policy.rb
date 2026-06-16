# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  # A client may only see their own projects. Admins see everything.
  def index?
    user.present?
  end

  def show?
    return false unless user

    user.admin? || record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
