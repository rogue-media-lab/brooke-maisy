class Tech::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_tech
  layout "tech"

  private

  def require_tech
    return if current_user&.tech?

    redirect_to root_path, alert: "Installer access only."
  end
end