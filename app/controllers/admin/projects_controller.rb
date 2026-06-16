class Admin::ProjectsController < Admin::BaseController
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

  def index
    @projects = Project.includes(:user).recent
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = @projects.where(user_id: params[:client_id]) if params[:client_id].present?
  end

  def show
    @updates = @project.project_updates.recent
    @new_update = @project.project_updates.build(visible_to_client: true)
  end

  def new
    @project = Project.new
    @project.user_id = params[:client_id] if params[:client_id].present?
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to admin_project_path(@project), notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to admin_project_path(@project), notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to admin_projects_path, notice: "Project deleted."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:user_id, :title, :description, :status, :address, photos: [])
  end
end
