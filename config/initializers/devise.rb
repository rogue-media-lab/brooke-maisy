# frozen_string_literal: true

# Assuming you have devise defined, you can add other configurations here
Devise.setup do |config|
  config.mailer_sender = 'noreply@brookeandmaisy.com'
  require 'devise/orm/active_record'
end