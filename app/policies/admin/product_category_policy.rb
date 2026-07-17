# frozen_string_literal: true

class Admin::ProductCategoryPolicy < ApplicationPolicy
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
