class Admin::ProductCategoriesController < Admin::BaseController
  before_action :set_product_category, only: [ :show, :edit, :update, :destroy ]

  def index
    @product_categories = ProductCategory.top_level
  end

  def show
  end

  def new
    @product_category = ProductCategory.new
    @parents = ProductCategory.ordered
  end

  def create
    @product_category = ProductCategory.new(product_category_params)
    if @product_category.save
      redirect_to admin_product_category_path(@product_category), notice: "Category added."
    else
      @parents = ProductCategory.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parents = ProductCategory.where.not(id: @product_category.id).ordered
  end

  def update
    if @product_category.update(product_category_params)
      redirect_to admin_product_category_path(@product_category), notice: "Category updated."
    else
      @parents = ProductCategory.where.not(id: @product_category.id).ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product_category.destroy
    redirect_to admin_product_categories_path, notice: "Category removed."
  end

  private

  def set_product_category
    @product_category = ProductCategory.find(params[:id])
  end

  def product_category_params
    params.require(:product_category).permit(:name, :slug, :parent_id, :spec_template, :markup_override)
  end
end
