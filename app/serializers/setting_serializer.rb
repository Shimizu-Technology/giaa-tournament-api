class SettingSerializer < ActiveModel::Serializer
  attributes :id, :max_capacity, :stripe_public_key, :stripe_secret_key,
             :stripe_webhook_secret, :tournament_entry_fee, :entry_fee_dollars,
             :admin_email, :payment_mode, :registration_open, :created_at, :updated_at,
             :capacity_remaining, :at_capacity, :stripe_configured, :test_mode,
             # Tournament configuration
             :tournament_year, :tournament_edition, :tournament_title, :tournament_name,
             :event_date, :registration_time, :start_time, :location_name, :location_address,
             :format_name, :fee_includes, :checks_payable_to, :contact_name, :contact_phone

  def capacity_remaining
    object.capacity_remaining
  end

  def at_capacity
    object.at_capacity?
  end

  def stripe_configured
    object.stripe_configured?
  end

  def entry_fee_dollars
    object.entry_fee_dollars
  end

  def test_mode
    object.test_mode?
  end

  # Hide secret keys by default, only shown to authorized admins
  def stripe_secret_key
    if instance_options[:hide_secrets]
      nil
    else
      object.stripe_secret_key
    end
  end

  def stripe_webhook_secret
    if instance_options[:hide_secrets]
      nil
    else
      object.stripe_webhook_secret
    end
  end
end

