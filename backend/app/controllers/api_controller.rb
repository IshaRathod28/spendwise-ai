# frozen_string_literal: true

# ApiController - Base controller for API endpoints
# Inherits from ActionController::API for JSON responses without view rendering
class ApiController < ActionController::API
  # Skip CSRF protection for API endpoints
  # API clients will use other authentication methods
end
