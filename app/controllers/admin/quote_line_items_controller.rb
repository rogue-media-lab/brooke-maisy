class Admin::QuoteLineItemsController < Admin::BaseController
  before_action :set_quote

  def new
    @quote_line_item = @quote.quote_line_items.new
    @products = Product.active.ordered.includes(:manufacturer)
    @windows = @quote.project.rooms.flat_map(&:windows)
    @swatches = Swatch.active.ordered.includes(:manufacturer)
  end

  def create
    @quote_line_item = @quote.quote_line_items.new(line_item_params)
    @quote_line_item.position = @quote.quote_line_items.count
    if @quote_line_item.save
      redirect_to admin_project_quote_path(@quote.project, @quote), notice: "Line item added."
    else
      @products = Product.active.ordered.includes(:manufacturer)
      @windows = @quote.project.rooms.flat_map(&:windows)
      @swatches = Swatch.active.ordered.includes(:manufacturer)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @quote_line_item = @quote.quote_line_items.find(params[:id])
    @products = Product.active.ordered.includes(:manufacturer)
    @windows = @quote.project.rooms.flat_map(&:windows)
    @swatches = Swatch.active.ordered.includes(:manufacturer)
  end

  def update
    @quote_line_item = @quote.quote_line_items.find(params[:id])
    if @quote_line_item.update(line_item_params)
      redirect_to admin_project_quote_path(@quote.project, @quote), notice: "Line item updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quote.quote_line_items.find(params[:id]).destroy
    redirect_to admin_project_quote_path(@quote.project, @quote), notice: "Line item removed."
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id])
  end

  def line_item_params
    params.require(:quote_line_item).permit(
      :product_id, :window_id, :swatch_id, :description,
      :width, :height, :quantity, :unit_cost, :unit_price,
      :discount_type, :discount_value, :discount_reason,
      :status, :notes
    )
  end
end
