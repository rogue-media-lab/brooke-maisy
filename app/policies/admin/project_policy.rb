# frozen_string_literal: true

# Admin-only management of projects. Brooke (admin) can do everything;
# non-admins are denied at the controller level (Admin::BaseController),
# but these policies make the intent explicit and testable.
class Admin::ProjectPolicy < ApplicationPolicy
  def index?   = user&.admin?
  def show?    = user&.admin?
  def create?  = user&.admin?
  def update?  = user&.admin?
  def destroy? = user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.admin? ? scope.all : scope.none
    end
  end
end
