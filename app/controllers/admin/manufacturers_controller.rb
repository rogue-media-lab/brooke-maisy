class Admin::ManufacturersController < Admin::BaseController
  before_action :set_manufacturer, only: [ :show, :edit, :update, :destroy ]

  def index
    @manufacturers = Manufacturer.ordered
  end

  def show
  end

  def new
    @manufacturer = Manufacturer.new
  end

  def create
    @manufacturer = Manufacturer.new(manufacturer_params)
    if @manufacturer.save
      redirect_to admin_manufacturer_path(@manufacturer), notice: "Manufacturer added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @manufacturer.update(manufacturer_params)
      redirect_to admin_manufacturer_path(@manufacturer), notice: "Manufacturer updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @manufacturer.destroy
    redirect_to admin_manufacturers_path, notice: "Manufacturer removed."
  end

  private

  def set_manufacturer
    @manufacturer = Manufacturer.find(params[:id])
  end

  def manufacturer_params
    params.require(:manufacturer).permit(:name, :website, :trade_program_url, :trade_discount, :markup_override, :notes)
  end
end
