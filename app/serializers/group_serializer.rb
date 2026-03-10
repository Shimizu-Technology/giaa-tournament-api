class GroupSerializer < ActiveModel::Serializer
  attributes :id, :tournament_id, :group_number, :hole_number, :created_at, :updated_at,
             :golfer_count, :is_full, :hole_position_label

  has_many :golfers

  def golfer_count
    # Use .size instead of .count to leverage eager-loaded associations
    object.golfers.size
  end

  def is_full
    object.golfers.size >= Group::MAX_GOLFERS
  end

  # Hole-based label for the group (e.g., "7A" for first foursome at Hole 7)
  # Uses precomputed label if available (set by controller), otherwise falls back to in-memory calculation
  def hole_position_label
    return object.instance_variable_get(:@precomputed_hole_label) if object.instance_variable_defined?(:@precomputed_hole_label)
    return "Unassigned" unless object.hole_number

    # Fallback: compute from model method (may trigger query if not precomputed)
    object.hole_position_label
  end
end
