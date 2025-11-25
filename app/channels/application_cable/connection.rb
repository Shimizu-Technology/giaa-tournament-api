module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_admin

    def connect
      self.current_admin = find_verified_admin
    end

    private

    def find_verified_admin
      # For ActionCable, we accept the connection and verify on subscription
      # This is simpler for WebSocket connections where we might not have
      # full JWT verification on initial connect
      #
      # For now, we allow all connections but verify on channel subscription
      # In production, you might want to verify the JWT token here as well
      true
    rescue StandardError
      reject_unauthorized_connection
    end
  end
end

