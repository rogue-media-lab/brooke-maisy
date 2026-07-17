class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @products = Product.includes(:manufacturer, :product_category).ordered
  end

  def search
    @products = Product.active
      .where("name ILIKE ?", "%#{params[:q]}%")
      .includes(:manufacturer)
      .limit(10)
    render json: @products.map { |p|
      {
        id: p.id,
        name: p.name,
        manufacturer: p.manufacturer&.name,
        specs: p.specs
      }
    }
  end

  def show
  end

  def new
    @product = Product.new
    @manufacturers = Manufacturer.ordered
    @categories = ProductCategory.ordered
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_product_path(@product), notice: "Product added."
    else
      @manufacturers = Manufacturer.ordered
      @categories = ProductCategory.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @manufacturers = Manufacturer.ordered
    @categories = ProductCategory.ordered
  end

  def update
    if @product.update(product_params)
      redirect_to admin_product_path(@product), notice: "Product updated."
    else
      @manufacturers = Manufacturer.ordered
      @categories = ProductCategory.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path, notice: "Product removed."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :manufacturer_id, :product_category_id, :name, :description,
      :product_url, :unit, :lead_time_days, :is_active, :tier, :notes,
      specs: {}, pricing: {}, images: {}, videos: {}, documents: {}
    )
  end
end
