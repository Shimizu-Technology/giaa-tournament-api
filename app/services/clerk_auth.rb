require "jwt"
require "net/http"
require "openssl"

class ClerkAuth
  class << self
    def verify(token)
      return nil if token.blank?

      # In test environment, allow special test tokens
      if Rails.env.test? && token.start_with?("test_token_")
        admin_id = token.gsub("test_token_", "")
        admin = Admin.find_by(id: admin_id)
        if admin
          return {
            "sub" => admin.clerk_id || "test_clerk_#{admin.id}",
            "email" => admin.email,
            "name" => admin.name
          }
        end
        return nil
      end

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
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 5
        http.read_timeout = 5
        
        # In development, be more lenient with SSL verification
        # In production, this should use proper CA certificates
        if Rails.env.development?
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
        
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)

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

