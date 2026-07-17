# frozen_string_literal: true

class Admin::PurchaseOrderPolicy < ApplicationPolicy
  def index?   = user&.admin?
  def show?    = user&.admin?
  def new?     = user&.admin?
  def create?  = user&.admin?
  def edit?    = user&.admin?
  def update?  = user&.admin?
  def destroy? = user&.admin?
  def submit?  = user&.admin?
  def confirm_delivery? = user&.admin?
  def mark_shipped?     = user&.admin?
  def mark_received?    = user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.admin? ? scope.all : scope.none
    end
  end
end
