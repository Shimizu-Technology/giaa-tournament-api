class Group < ApplicationRecord
  belongs_to :tournament
  has_many :golfers, dependent: :nullify

  validates :group_number, presence: true, uniqueness: { scope: :tournament_id }
  validates :hole_number, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 18 }, allow_nil: true
  validates :tournament_id, presence: true

  scope :with_golfers, -> { includes(:golfers).order(:group_number) }
  scope :for_tournament, ->(tournament_id) { where(tournament_id: tournament_id) }

  # Maximum golfers per group
  MAX_GOLFERS = 4

  def full?
    golfers.count >= MAX_GOLFERS
  end

  def golfer_labels
    golfers.order(:position).map.with_index do |golfer, index|
      letter = ("a".."d").to_a[index]
      { golfer: golfer, label: "#{group_number}#{letter.upcase}" }
    end
  end

  def add_golfer(golfer)
    return false if full?

    next_position = golfers.count + 1
    golfer.update!(group: self, position: next_position)
    true
  end

  def remove_golfer(golfer)
    golfer.update!(group: nil, position: nil)
    reorder_positions
  end

  private

  def reorder_positions
    golfers.order(:position).each_with_index do |golfer, index|
      golfer.update_column(:position, index + 1)
    end
  end
end
