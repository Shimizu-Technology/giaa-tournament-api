# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from localhost during development and production domains
    origins "localhost:3000", "localhost:5173", "localhost:5174", 
            "127.0.0.1:3000", "127.0.0.1:5173", "127.0.0.1:5174",
            # Production frontend URLs (explicitly listed)
            "https://giaa-tournament.com",
            "https://www.giaa-tournament.com",
            # Legacy misspelled domain (redirect will handle this)
            "https://giaa-tournment.com",
            "https://www.giaa-tournment.com",
            # Also allow from FRONTEND_URL env var if set
            *([ENV["FRONTEND_URL"]].compact)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ["Authorization"]
  end
end
