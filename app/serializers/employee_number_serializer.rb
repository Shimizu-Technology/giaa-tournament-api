class EmployeeNumberSerializer < ActiveModel::Serializer
  attributes :id, :tournament_id, :employee_number, :employee_name,
             :used, :used_by_golfer_id, :used_by_golfer_name,
             :display_name, :status, :created_at

  def used_by_golfer_name
    object.used_by_golfer&.name
  end

  def display_name
    object.display_name
  end

  def status
    object.status
  end

  def created_at
    object.created_at.in_time_zone('Guam').iso8601
  end
end

