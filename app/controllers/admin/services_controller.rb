class Admin::ServicesController < Admin::BaseController
  before_action :set_service, only: [ :show, :edit, :update, :destroy ]

  def index
    @services = Service.ordered
  end

  def show
  end

  def new
    @service = Service.new
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to admin_service_path(@service), notice: "Service added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to admin_service_path(@service), notice: "Service updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy
    redirect_to admin_services_path, notice: "Service removed."
  end

  private

  def set_service
    @service = Service.find(params[:id])
  end

  def service_params
    params.require(:service).permit(
      :title, :description, :icon_name, :bullet_points,
      :display_order, :active
    )
  end
end
