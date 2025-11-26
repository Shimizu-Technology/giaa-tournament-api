class SettingSerializer < ActiveModel::Serializer
  attributes :id, :max_capacity, :stripe_public_key, :stripe_secret_key,
             :stripe_webhook_secret, :tournament_entry_fee, :entry_fee_dollars,
             :admin_email, :payment_mode, :created_at, :updated_at,
             :capacity_remaining, :at_capacity, :stripe_configured, :test_mode

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

