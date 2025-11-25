class SettingSerializer < ActiveModel::Serializer
  attributes :id, :max_capacity, :stripe_public_key, :stripe_secret_key,
             :admin_email, :created_at, :updated_at,
             :capacity_remaining, :at_capacity

  def capacity_remaining
    object.capacity_remaining
  end

  def at_capacity
    object.at_capacity?
  end

  # Hide secret key by default, only shown to super admins
  def stripe_secret_key
    if instance_options[:hide_secrets]
      nil
    else
      object.stripe_secret_key
    end
  end
end

