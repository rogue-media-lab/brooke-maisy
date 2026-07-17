# app/services/quote_calculator.rb
# All pricing math in one place. Testable in isolation.
#
# Called on every quote save and whenever Amanda views the quote.
# Turbo Streams push updated numbers to the DOM without a page reload.
#
# Usage: QuoteCalculator.new(quote).calculate
# Returns a hash with all computed values.

class QuoteCalculator
  DEFAULT_MARKUP = 0.40  # 40%

  def initialize(quote)
    @quote = quote
  end

  def calculate
    line_results = calculate_line_items

    {
      line_items: line_results,
      subtotal: line_results.sum { |li| li[:line_total] },
      quote_discount: compute_quote_discount(line_results.sum { |li| li[:line_total] }),
      adjusted_subtotal: nil,  # computed below
      tax_amount: nil,
      grand_total: nil,
      total_cost: line_results.sum { |li| li[:configured_cost] },
      gross_profit: nil,
      profit_margin_pct: nil,
      deposit_amount: nil,
      balance_due: nil
    }.tap do |results|
      results[:adjusted_subtotal] = results[:subtotal] - results[:quote_discount]
      results[:tax_amount] = results[:adjusted_subtotal] * tax_rate
      results[:grand_total] = results[:adjusted_subtotal] + results[:tax_amount]
      results[:gross_profit] = results[:grand_total] - results[:total_cost]
      results[:profit_margin_pct] = results[:grand_total] > 0 ? (results[:gross_profit] / results[:grand_total] * 100).round(1) : 0
      results[:deposit_amount] = deposit_percentage ? (results[:grand_total] * deposit_percentage).round(2) : 0
      results[:balance_due] = results[:grand_total] - results[:deposit_amount]
    end
  end

  private

  def calculate_line_items
    @quote.quote_line_items.map do |item|
      configured_cost = compute_configured_cost(item)
      suggested_retail = configured_cost * (1 + markup_rate_for(item))
      adjusted_retail = apply_line_discount(suggested_retail, item)
      line_total = adjusted_retail * (item.quantity || 1)

      {
        id: item.id,
        configured_cost: configured_cost.round(2),
        suggested_retail: suggested_retail.round(2),
        adjusted_retail: adjusted_retail.round(2),
        line_total: line_total.round(2)
      }
    end
  end

  def compute_configured_cost(item)
    cost = item.unit_cost || 0
    # Add upcharges from selected_options if product has specs
    if item.product && item.selected_options.present?
      specs = item.product.specs || {}
      options = item.selected_options

      # Sum upcharges from lift_styles, upgrades, warranty_options
      cost += upcharge_for(specs["lift_styles"], options["lift_style"])
      cost += upcharge_for(specs["upgrades"], options["upgrade"])
      cost += upcharge_for(specs["warranty_options"], options["warranty"])
    end
    cost
  end

  def upcharge_for(options_array, selected_name)
    return 0 unless options_array && selected_name
    option = options_array.find { |o| o["name"] == selected_name }
    option ? option["upcharge"].to_f : 0
  end

  def markup_rate_for(item)
    product = item.product
    return DEFAULT_MARKUP unless product

    manufacturer_rate = product.manufacturer.markup_override
    category_rate = product.product_category.markup_override

    # Resolution: manufacturer override > category override > default
    (manufacturer_rate || category_rate || DEFAULT_MARKUP).to_f
  end

  def apply_line_discount(suggested_retail, item)
    return suggested_retail unless item.discount_value.to_f > 0
    case item.discount_type
    when "percentage"
      suggested_retail * (1 - item.discount_value.to_f / 100)
    when "fixed"
      [ suggested_retail - item.discount_value.to_f, 0 ].max
    else
      suggested_retail
    end
  end

  def compute_quote_discount(subtotal)
    return 0 unless @quote.quote_discount_value.to_f > 0
    case @quote.quote_discount_type
    when "percentage"
      subtotal * @quote.quote_discount_value.to_f / 100
    when "fixed"
      [ @quote.quote_discount_value.to_f, subtotal ].min
    else
      0
    end
  end

  def tax_rate
    @quote.tax_rate || 0.06  # SC default
  end

  def deposit_percentage
    @quote.deposit_percentage&.then { |p| p / 100.0 }
  end
end
