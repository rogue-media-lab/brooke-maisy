class ChecklistItemPolicy < ApplicationPolicy
  def index?    = admin?
  def create?   = admin?
  def update?   = admin?
  def destroy?  = admin?
  def show?     = true # techs need to read for their checklist

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private

  def admin?
    user&.admin?
  end
end