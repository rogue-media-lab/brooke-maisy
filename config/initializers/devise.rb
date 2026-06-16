# frozen_string_literal: true

# Assuming you have devise defined, you can add other configurations here
Devise.setup do |config|
  config.mailer_sender = "noreply@brookeandmaisy.com"

  # Use scoped views under app/views/users/ (scoped to the :users mapping)
  # so our custom olive-styled sessions/passwords views are picked up.
  config.scoped_views = true
  require "devise/orm/active_record"
end
