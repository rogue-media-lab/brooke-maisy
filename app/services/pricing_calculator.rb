# app/services/pricing_calculator.rb
#
# Interpolates product costs from reference price points stored in product.pricing JSONB.
# Handles mount type dimension adjustments, option upcharges, and markup application.
#
# Usage:
#   result = PricingCalculator.new(product, width, height, selected_options, quantity, override_cost).calculate
#   result[:base_cost]     # interpolated cost (or override)
#   result[:upcharges]     # sum of option upcharges
#   result[:unit_cost]     # base_cost + upcharges (what Amanda pays)
#   result[:unit_price]    # unit_cost * (1 + markup) (what client pays)
#   result[:line_total]    # unit_price * quantity
#   result[:method]        # :interpolated, :override, :no_pricing, :single_point
#
# Called on quote line item save (server-side source of truth).
# The Stimulus quote_calculator_controller mirrors this logic client-side for live preview.

class PricingCalculator
  DEFAULT_MARKUP = 0.40

  def initialize(product, width, height, selected_options = {}, quantity = 1, override_cost = nil)
    @product = product
    @width = width.to_f
    @height = height.to_f
    @selected_options = selected_options || {}
    @quantity = quantity.to_i
    @quantity = 1 if @quantity < 1
    @override_cost = override_cost
    @method = :interpolated
  end

  def calculate
    adjusted_width, adjusted_height = apply_mount_adjustments

    base_cost = compute_base_cost(adjusted_width, adjusted_height)
    upcharges = sum_upcharges
    unit_cost = base_cost + upcharges
    unit_price = unit_cost * (1 + markup_rate)
    line_total = unit_price * @quantity

    {
      base_cost: base_cost.round(2),
      upcharges_total: upcharges.round(2),
      unit_cost: unit_cost.round(2),
      unit_price: unit_price.round(2),
      line_total: line_total.round(2),
      adjusted_width: adjusted_width,
      adjusted_height: adjusted_height,
      method: @method
    }
  end

  private

  # --- Mount Type Dimension Adjustments ---

  def apply_mount_adjustments
    mount_type = @selected_options["mount_type"]
    return [ @width, @height ] unless mount_type

    specs = @product&.specs || {}
    mount_options = specs["mount_types"] || []
    # mount_types can be array of strings (old format) or array of hashes (new format)
    mount = mount_options.find do |m|
      m.is_a?(Hash) ? m["name"] == mount_type : m == mount_type
    end

    return [ @width, @height ] unless mount.is_a?(Hash)

    w_adj = mount["width_adjustment"].to_f
    h_adj = mount["height_adjustment"].to_f
    [ @width + w_adj, @height + h_adj ]
  end

  # --- Base Cost Interpolation ---

  def compute_base_cost(width, height)
    if @override_cost.present?
      @method = :override
      return @override_cost.to_f.round(2)
    end

    # No pricing data at all
    return no_pricing if pricing_data.blank?

    # Flat base_cost fallback — products without size-based price_points
    if price_points.empty? && pricing_data["base_cost"].present?
      @method = :single_point
      return pricing_data["base_cost"].to_f.round(2)
    end

    return no_pricing if price_points.empty?
    return single_point_cost(height) if price_points.size == 1

    interpolate(width, height)
  end

  def no_pricing
    @method = :no_pricing
    0.0
  end

  def single_point_cost(height)
    @method = :single_point
    point = price_points.first
    base = point[:cost].to_f
    apply_height_adjustment(base, point[:height].to_f, height)
  end

  def interpolate(width, height)
    @method = :interpolated
    points = price_points.sort_by { |p| p[:width].to_f }

    r1, r2 = find_bracket(points, width)
    return points.first[:cost].to_f if r1.nil? || r2.nil?

    width_range = r2[:width].to_f - r1[:width].to_f
    frac = width_range.zero? ? 0.0 : (width - r1[:width].to_f) / width_range

    interp_cost = r1[:cost].to_f + frac * (r2[:cost].to_f - r1[:cost].to_f)
    interp_height = r1[:height].to_f + frac * (r2[:height].to_f - r1[:height].to_f)

    apply_height_adjustment(interp_cost, interp_height, height)
  end

  def apply_height_adjustment(cost, ref_height, actual_height)
    return cost.round(2) if ref_height <= 0

    height_factor = (pricing_data["height_factor"] || 0.5).to_f
    adjustment = 1 + height_factor * (actual_height - ref_height) / ref_height
    (cost * adjustment).round(2)
  end

  def find_bracket(points, width)
    # Exact match
    exact = points.find { |p| p[:width].to_f == width }
    return [ exact, exact ] if exact

    # Below minimum (extrapolate)
    return [ points[0], points[1] ] if width < points.first[:width].to_f

    # Above maximum (extrapolate)
    return [ points[-2], points[-1] ] if width > points.last[:width].to_f

    # Between two points
    points.each_cons(2) do |a, b|
      return [ a, b ] if width >= a[:width].to_f && width <= b[:width].to_f
    end

    [ nil, nil ]
  end

  # --- Upcharges ---

  def sum_upcharges
    return 0.0 if @selected_options.blank?

    specs = @product&.specs || {}
    total = 0.0

    @selected_options.each do |key, value|
      next if value.blank?
      upcharge = find_upcharge(specs, key, value)
      total += upcharge if upcharge
    end

    total
  end

  def find_upcharge(specs, key, value)
    specs_key = pluralize_spec_key(key)
    options = specs[specs_key]
    return nil unless options.is_a?(Array)

    option = options.find { |o| o.is_a?(Hash) && o["name"] == value }
    option ? option["upcharge"].to_f : 0.0
  end

  def pluralize_spec_key(key)
    case key.to_s
    when "lift_style" then "lift_styles"
    when "mount_type" then "mount_types"
    when "upgrade" then "upgrades"
    when "warranty" then "warranty_options"
    else key.to_s
    end
  end

  # --- Markup ---

  def markup_rate
    product = @product
    return DEFAULT_MARKUP unless product

    manufacturer_rate = product.manufacturer&.markup_override
    return manufacturer_rate.to_f if manufacturer_rate

    category_rate = product.product_category&.markup_override
    return category_rate.to_f if category_rate

    DEFAULT_MARKUP
  end

  # --- Pricing Data Access ---

  def pricing_data
    @pricing_data ||= @product&.pricing || {}
  end

  def price_points
    @price_points ||= (pricing_data["price_points"] || []).map(&:with_indifferent_access)
  end
end
