require "test_helper"

class PricingCalculatorTest < ActiveSupport::TestCase
  # Real SelectBlinds data points for Cordless Light Filtering Cellular Shades
  REFERENCE_POINTS = [
    { "width" => 24, "height" => 36, "cost" => 71.99 },
    { "width" => 36, "height" => 48, "cost" => 146.99 },
    { "width" => 60, "height" => 60, "cost" => 243.99 },
    { "width" => 72, "height" => 48, "cost" => 254.99 }
  ].freeze

  def setup
    @manufacturer = Manufacturer.create!(name: "TestBlinds", markup_override: nil)
    @category = ProductCategory.create!(name: "Cellular Shades", slug: "cellular-shades")
    @product = Product.create!(
      name: "Test Cellular Shade",
      manufacturer: @manufacturer,
      product_category: @category,
      is_active: true,
      specs: {
        "lift_styles" => [
          { "name" => "cordless", "upcharge" => 0 },
          { "name" => "motorized", "upcharge" => 87.17 }
        ],
        "mount_types" => [
          { "name" => "inside", "width_adjustment" => 0, "height_adjustment" => 0 },
          { "name" => "outside", "width_adjustment" => 4, "height_adjustment" => 2 }
        ],
        "upgrades" => [
          { "name" => "no_drill", "upcharge" => 28.00 }
        ]
      },
      pricing: {
        "price_points" => REFERENCE_POINTS,
        "height_factor" => 0.5
      }
    )
  end

  # --- Interpolation Tests ---

  test "returns exact cost when size matches a reference point" do
    result = PricingCalculator.new(@product, 36, 48).calculate
    assert_equal 146.99, result[:base_cost]
    assert_equal :interpolated, result[:method]
  end

  test "interpolates between two reference points" do
    # 30x42 is between 24x36 ($71.99) and 36x48 ($146.99)
    # Width frac: (30-24)/(36-24) = 0.5
    # Interp cost: 71.99 + 0.5*(146.99-71.99) = 109.49
    # Interp height: 36 + 0.5*(48-36) = 42 (exact match, no height adjustment)
    result = PricingCalculator.new(@product, 30, 42).calculate
    assert_equal 109.49, result[:base_cost]
  end

  test "applies height adjustment when height differs from interpolated height" do
    # 30x60: width=30 interpolates to cost=109.49, height=42
    # Height adjustment: 1 + 0.5 * (60-42)/42 = 1.2143
    # Expected: 109.49 * 1.2143 = 132.96
    result = PricingCalculator.new(@product, 30, 60).calculate
    assert_in_delta 132.96, result[:base_cost], 0.10
  end

  # --- Override Cost Tests ---

  test "uses override_cost when present" do
    result = PricingCalculator.new(@product, 36, 48, {}, 1, 99.99).calculate
    assert_equal 99.99, result[:base_cost]
    assert_equal :override, result[:method]
  end

  test "override_cost takes precedence over interpolation" do
    # Even with a size that matches a reference point, override wins
    result = PricingCalculator.new(@product, 36, 48, {}, 1, 50.00).calculate
    assert_equal 50.00, result[:base_cost]
  end

  # --- No Pricing Data Tests ---

  test "returns zero cost when product has no pricing data" do
    @product.update!(pricing: {})
    result = PricingCalculator.new(@product, 36, 48).calculate
    assert_equal 0.0, result[:base_cost]
    assert_equal :no_pricing, result[:method]
  end

  test "returns zero cost when pricing is nil" do
    @product.update!(pricing: nil)
    result = PricingCalculator.new(@product, 36, 48).calculate
    assert_equal 0.0, result[:base_cost]
  end

  test "uses single reference point directly when only one exists" do
    @product.update!(pricing: { "price_points" => [ REFERENCE_POINTS[0] ], "height_factor" => 0.5 })
    # Single point: 24x36 at $71.99. Request exact size = no height adjustment.
    result = PricingCalculator.new(@product, 24, 36).calculate
    assert_equal 71.99, result[:base_cost]
  end

  # --- Upcharge Tests ---

  test "sums upcharges from selected options" do
    options = { "lift_style" => "motorized" }
    result = PricingCalculator.new(@product, 36, 48, options).calculate
    assert_equal 146.99, result[:base_cost]
    assert_equal 87.17, result[:upcharges_total]
    assert_equal 234.16, result[:unit_cost] # 146.99 + 87.17
  end

  test "adds multiple upcharges" do
    options = { "lift_style" => "motorized", "upgrade" => "no_drill" }
    result = PricingCalculator.new(@product, 36, 48, options).calculate
    assert_equal 115.17, result[:upcharges_total] # 87.17 + 28.00
  end

  test "returns zero upcharges when no options selected" do
    result = PricingCalculator.new(@product, 36, 48, {}).calculate
    assert_equal 0.0, result[:upcharges_total]
  end

  # --- Mount Type Adjustment Tests ---

  test "applies outside mount width and height adjustments" do
    # Window: 36x48, outside mount: +4 width, +2 height
    # Adjusted: 40x50
    # 40" width interpolates between 36x48 ($146.99) and 60x60 ($243.99)
    # Width frac: (40-36)/(60-36) = 0.1667
    # Interp cost: 146.99 + 0.1667*(243.99-146.99) = 163.16
    # Interp height: 48 + 0.1667*(60-48) = 50 (exact match, no height adjustment)
    options = { "mount_type" => "outside" }
    result = PricingCalculator.new(@product, 36, 48, options).calculate
    assert_in_delta 163.16, result[:base_cost], 0.10
    assert_equal 40, result[:adjusted_width]
    assert_equal 50, result[:adjusted_height]
  end

  test "inside mount applies no adjustments" do
    options = { "mount_type" => "inside" }
    result = PricingCalculator.new(@product, 36, 48, options).calculate
    assert_equal 36, result[:adjusted_width]
    assert_equal 48, result[:adjusted_height]
    assert_equal 146.99, result[:base_cost]
  end

  test "no mount type selection applies no adjustments" do
    result = PricingCalculator.new(@product, 36, 48, {}).calculate
    assert_equal 36, result[:adjusted_width]
    assert_equal 48, result[:adjusted_height]
  end

  test "handles old-style string mount_types without adjustments" do
    @product.update!(specs: {
      "mount_types" => [ "inside", "outside" ],
      "lift_styles" => [ { "name" => "cordless", "upcharge" => 0 } ]
    })
    options = { "mount_type" => "outside" }
    result = PricingCalculator.new(@product, 36, 48, options).calculate
    assert_equal 36, result[:adjusted_width]
    assert_equal 48, result[:adjusted_height]
  end

  # --- Markup Tests ---

  test "applies default 40% markup" do
    result = PricingCalculator.new(@product, 36, 48).calculate
    # base_cost = 146.99, upcharges = 0, unit_cost = 146.99
    # unit_price = 146.99 * 1.40 = 205.79
    assert_in_delta 205.79, result[:unit_price], 0.01
  end

  test "uses manufacturer markup override when set" do
    @manufacturer.update!(markup_override: 0.50)
    result = PricingCalculator.new(@product, 36, 48).calculate
    # 146.99 * 1.50 = 220.49
    assert_in_delta 220.49, result[:unit_price], 0.01
  end

  test "uses category markup override when manufacturer has none" do
    @category.update!(markup_override: 0.35)
    result = PricingCalculator.new(@product, 36, 48).calculate
    # 146.99 * 1.35 = 198.44
    assert_in_delta 198.44, result[:unit_price], 0.01
  end

  test "manufacturer override takes precedence over category override" do
    @manufacturer.update!(markup_override: 0.50)
    @category.update!(markup_override: 0.35)
    result = PricingCalculator.new(@product, 36, 48).calculate
    # Should use 0.50 (manufacturer wins)
    assert_in_delta 220.49, result[:unit_price], 0.01
  end

  # --- Quantity Tests ---

  test "multiplies unit_price by quantity for line_total" do
    result = PricingCalculator.new(@product, 36, 48, {}, 3).calculate
    # unit_price = 205.79, line_total = 205.79 * 3 = 617.36
    assert_in_delta 617.36, result[:line_total], 0.01
  end

  test "defaults quantity to 1" do
    result = PricingCalculator.new(@product, 36, 48).calculate
    assert_in_delta 205.79, result[:line_total], 0.01
  end

  # --- Edge Cases ---

  test "extrapolates below minimum reference point" do
    # 18x36: below 24x36 ($71.99)
    # Uses points [24x36, 36x48] for extrapolation
    # Width frac: (18-24)/(36-24) = -0.5
    # Interp cost: 71.99 + (-0.5)*(146.99-71.99) = 34.49
    # Interp height: 36 + (-0.5)*(48-36) = 30
    # Height adjustment: 1 + 0.5*(36-30)/30 = 1.1
    # Expected: 34.49 * 1.1 = 37.94
    result = PricingCalculator.new(@product, 18, 36).calculate
    assert_in_delta 37.94, result[:base_cost], 0.10
  end

  test "extrapolates above maximum reference point" do
    # 84x48: above 72x48 ($254.99)
    # Uses points [60x60, 72x48] for extrapolation
    # Width frac: (84-60)/(72-60) = 2.0
    # Interp cost: 243.99 + 2.0*(254.99-243.99) = 243.99 + 22.00 = 265.99
    # Interp height: 60 + 2.0*(48-60) = 60 - 24 = 36
    # Height adjustment: 1 + 0.5*(48-36)/36 = 1.1667
    # Expected: 265.99 * 1.1667 = 310.31
    result = PricingCalculator.new(@product, 84, 48).calculate
    assert_in_delta 310.31, result[:base_cost], 0.50
  end
end
