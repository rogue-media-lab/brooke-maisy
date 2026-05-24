class ErrorsController < ApplicationController
  # Skip authentication so error pages are always accessible,
  # even if the authentication before_action or session lookup fails.
  skip_before_action :require_authentication, raise: false

  def not_found
    render status: :not_found
  end

  def unprocessable_entity
    render status: :unprocessable_entity
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
