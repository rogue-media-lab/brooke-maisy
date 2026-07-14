class Tech::DashboardPolicy < ApplicationPolicy
  def show?
    user&.tech?
  end
end