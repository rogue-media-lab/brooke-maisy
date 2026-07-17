# frozen_string_literal: true

class Admin::ProductPolicy < ApplicationPolicy
  def index?   = user&.admin?
  def show?    = user&.admin?
  def create?  = user&.admin?
  def update?  = user&.admin?
  def destroy? = user&.admin?
  def search?  = user&.admin?  # AJAX product search in quote builder

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.admin? ? scope.all : scope.none
    end
  end
end
