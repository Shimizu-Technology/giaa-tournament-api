require "test_helper"

class GroupTest < ActiveSupport::TestCase
  # ==================
  # Validations
  # ==================

  test "should be valid with group_number" do
    group = Group.new(group_number: 99)
    assert group.valid?
  end

  test "should require group_number" do
    group = Group.new(group_number: nil)
    assert_not group.valid?
    assert_includes group.errors[:group_number], "can't be blank"
  end

  test "should require unique group_number" do
    existing = groups(:group_one)
    group = Group.new(group_number: existing.group_number)
    assert_not group.valid?
    assert_includes group.errors[:group_number], "has already been taken"
  end

  test "hole_number is optional" do
    group = Group.new(group_number: 100, hole_number: nil)
    assert group.valid?
  end

  # ==================
  # Associations
  # ==================

  test "has many golfers" do
    group = groups(:group_one)
    assert_respond_to group, :golfers
    assert group.golfers.count >= 0
  end

  test "golfers are ordered by position" do
    group = groups(:group_one)
    positions = group.golfers.pluck(:position).compact
    assert_equal positions.sort, positions
  end

  # ==================
  # Scopes
  # ==================

  test "with_golfers scope includes golfers and orders by group_number" do
    groups_list = Group.with_golfers
    numbers = groups_list.pluck(:group_number)
    assert_equal numbers.sort, numbers
  end

  # ==================
  # Instance Methods
  # ==================

  test "full? returns false when under capacity" do
    group = groups(:group_three)
    group.golfers.destroy_all
    assert_not group.full?
  end

  test "MAX_GOLFERS constant is 4" do
    assert_equal 4, Group::MAX_GOLFERS
  end

  test "add_golfer assigns golfer to group" do
    group = groups(:group_three)
    group.golfers.destroy_all
    golfer = golfers(:confirmed_unpaid)
    
    result = group.add_golfer(golfer)
    
    assert result
    golfer.reload
    assert_equal group.id, golfer.group_id
    assert_equal 1, golfer.position
  end

  test "remove_golfer unassigns golfer from group" do
    golfer = golfers(:confirmed_paid)
    group = golfer.group
    
    group.remove_golfer(golfer)
    golfer.reload
    
    assert_nil golfer.group_id
    assert_nil golfer.position
  end
end
