class Admin::SwatchesController < Admin::BaseController
  before_action :set_swatch, only: [ :show, :edit, :update, :destroy ]

  def index
    @swatches = Swatch.includes(:manufacturer).ordered
  end

  def show
  end

  def new
    @swatch = Swatch.new
    @manufacturers = Manufacturer.ordered
  end

  def create
    @swatch = Swatch.new(swatch_params)
    if @swatch.save
      redirect_to admin_swatch_path(@swatch), notice: "Swatch added."
    else
      @manufacturers = Manufacturer.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @manufacturers = Manufacturer.ordered
  end

  def update
    if @swatch.update(swatch_params)
      redirect_to admin_swatch_path(@swatch), notice: "Swatch updated."
    else
      @manufacturers = Manufacturer.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @swatch.destroy
    redirect_to admin_swatches_path, notice: "Swatch removed."
  end

  private

  def set_swatch
    @swatch = Swatch.find(params[:id])
  end

  def swatch_params
    params.require(:swatch).permit(:manufacturer_id, :name, :hex, :category, :color_range, :image_url, :is_new, :is_active)
  end
end
