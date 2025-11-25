require "jwt"
require "net/http"

class ClerkAuth
  class << self
    def verify(token)
      return nil if token.blank?

      jwks = fetch_jwks
      return nil if jwks.nil?

      decoded = JWT.decode(token, nil, true, {
        algorithms: ["RS256"],
        jwks: jwks
      })

      decoded.first
    rescue JWT::DecodeError => e
      Rails.logger.error("JWT decode error: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("ClerkAuth error: #{e.message}")
      nil
    end

    private

    def fetch_jwks
      jwks_url = ENV["CLERK_JWKS_URL"]

      if jwks_url.blank?
        Rails.logger.warn("CLERK_JWKS_URL not set, authentication disabled")
        return nil
      end

      # Cache JWKS for 1 hour
      Rails.cache.fetch("clerk_jwks", expires_in: 1.hour) do
        uri = URI(jwks_url)
        response = Net::HTTP.get_response(uri)

        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)
          { keys: data["keys"] }
        else
          Rails.logger.error("Failed to fetch JWKS: #{response.code}")
          nil
        end
      end
    rescue StandardError => e
      Rails.logger.error("Failed to fetch JWKS: #{e.message}")
      nil
    end
  end
end

