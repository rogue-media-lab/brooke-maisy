require "capybara/rspec"

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
end
