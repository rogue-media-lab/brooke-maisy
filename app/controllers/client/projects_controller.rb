class Client::ProjectsController < ApplicationController
  before_action :authenticate_user!

  def index
    @projects = policy_scope(Project).recent
  end

  def show
    @project = Project.find(params[:id])
    authorize @project
    @updates = @project.project_updates.client_visible.recent
  end
end
