class GroupSerializer < ActiveModel::Serializer
  attributes :id, :tournament_id, :group_number, :hole_number, :created_at, :updated_at,
             :golfer_count, :is_full

  has_many :golfers

  def golfer_count
    object.golfers.count
  end

  def is_full
    object.full?
  end
end

