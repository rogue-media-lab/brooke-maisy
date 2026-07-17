class Admin::SettingsController < Admin::BaseController
  def margins
    @manufacturers = Manufacturer.ordered
    @categories = ProductCategory.top_level.includes(:children)
    @default_markup = QuoteCalculator::DEFAULT_MARKUP
  end
end
