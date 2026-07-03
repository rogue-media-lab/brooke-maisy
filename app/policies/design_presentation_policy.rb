class DesignPresentationPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def show?
    user&.admin? || record.published?
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.admin?
  end

  def move?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(status: "published")
      end
    end
  end
end
