class Admin::QuoteLineItemsController < Admin::BaseController
  before_action :set_quote

  def new
    @quote_line_item = @quote.quote_line_items.new
    load_form_data
  end

  def create
    @quote_line_item = @quote.quote_line_items.new(line_item_params)
    @quote_line_item.position = @quote.quote_line_items.count
    compute_pricing
    if @quote_line_item.save
      redirect_to admin_quote_path(@quote), notice: "Line item added."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @quote_line_item = @quote.quote_line_items.find(params[:id])
    load_form_data
  end

  def update
    @quote_line_item = @quote.quote_line_items.find(params[:id])
    compute_pricing
    if @quote_line_item.update(line_item_params)
      redirect_to admin_quote_path(@quote), notice: "Line item updated."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quote.quote_line_items.find(params[:id]).destroy
    redirect_to admin_quote_path(@quote), notice: "Line item removed."
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id])
  end

  def line_item_params
    params.require(:quote_line_item).permit(
      :product_id, :window_id, :swatch_id, :description, :location, :override_cost,
      :width, :height, :quantity, :unit_cost, :unit_price,
      :discount_type, :discount_value, :discount_reason,
      :status, :notes, :comparison_group,
      selected_options: {}
    )
  end

  def load_form_data
    @products = Product.active.ordered.includes(:manufacturer)
    @manufacturers = Manufacturer.ordered
    @windows = @quote.project ? @quote.project.rooms.flat_map(&:windows) : []
    @swatches = Swatch.active.ordered.includes(:manufacturer)
  end

  # Auto-compute unit_cost and unit_price from PricingCalculator
  # when a product and dimensions are present. For no-product line items
  # (description-only), the manually entered unit_cost/unit_price are kept.
  def compute_pricing
    product_id = params.dig(:quote_line_item, :product_id)
    width = params.dig(:quote_line_item, :width)
    height = params.dig(:quote_line_item, :height)
    return unless product_id.present? && width.present? && height.present?

    product = Product.find_by(id: product_id)
    return unless product

    selected_options = params.dig(:quote_line_item, :selected_options) || {}
    quantity = params.dig(:quote_line_item, :quantity) || 1
    override_cost = params.dig(:quote_line_item, :override_cost)

    result = PricingCalculator.new(
      product, width, height, selected_options, quantity, override_cost
    ).calculate

    params[:quote_line_item][:unit_cost] = result[:unit_cost]
    params[:quote_line_item][:unit_price] = result[:unit_price]
  end
end
