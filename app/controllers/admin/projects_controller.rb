class Admin::ProjectsController < Admin::BaseController
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

  def index
    @projects = Project.includes(:client).recent
    @projects = @projects.where(status: params[:status]) if params[:status].present?
    @projects = @projects.where(client_id: params[:client_id]) if params[:client_id].present?
  end

  def show
    @updates = @project.project_updates.recent
    @new_update = @project.project_updates.build(visible_to_client: true)
    @rooms = @project.rooms.includes(:windows).ordered
    @quotes = @project.quotes.live.includes(:client).recent.limit(5)
  end

  def new
    @project = Project.new
    @project.client_id = params[:client_id] if params[:client_id].present?
    @clients = Client.alphabetical
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
    if params[:project][:remove_photos].present?
      ids_to_remove = params[:project][:remove_photos].reject(&:blank?)
      @project.photos.select { |p| ids_to_remove.include?(p.signed_id) }.each(&:purge) if ids_to_remove.any?
    end

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
    params.require(:project).permit(:client_id, :title, :description, :status, :address, photos: [])
  end
end
