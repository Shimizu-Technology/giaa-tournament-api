# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create default settings
setting = Setting.find_or_create_by!(id: 1) do |s|
  s.max_capacity = 160
  s.admin_email = "shimizutechnology@gmail.com"
end
puts "Created settings with capacity: #{setting.max_capacity}"

# Create initial admin by email (they'll be linked when they first log in via Clerk)
# IMPORTANT: Change this email to your actual admin email before running in production!
initial_admin_email = ENV.fetch("INITIAL_ADMIN_EMAIL", "shimizutechnology@gmail.com")

admin = Admin.find_or_create_by!(email: initial_admin_email.downcase) do |a|
  a.name = "Tournament Admin"
  a.role = "admin"
  # clerk_id will be set automatically when admin first logs in
end
puts "Created initial admin: #{admin.email} (will be linked when they log in via Clerk)"

# Create a default tournament
tournament = Tournament.find_or_create_by!(name: "Edward A.P. Muna II Memorial Golf Tournament") do |t|
  t.year = 2026
  t.edition = "5th"
  t.event_date = Date.new(2026, 1, 9)
  t.registration_time = "11:00 am"
  t.start_time = "12:30 pm"
  t.max_capacity = 160
  t.reserved_slots = 0
  t.entry_fee = 12500 # $125.00 in cents
  t.employee_entry_fee = 5000 # $50.00 in cents
  t.registration_open = true
  t.status = "open"
  t.location_name = "Country Club of the Pacific"
  t.location_address = "Windward Hills, Guam"
  t.format_name = "Individual Callaway"
  t.fee_includes = "Green Fee, Ditty Bag, Drinks & Food"
  t.checks_payable_to = "GIAAEO"
  t.contact_name = "Peter Torres"
  t.contact_phone = "671.689.8677"
end
puts "Created tournament: #{tournament.name} (#{tournament.year})"

# Only seed sample data in development
if Rails.env.development?
  puts "Creating sample golfers for development..."

  # Create some sample golfers
  sample_golfers = [
    { name: "John Smith", company: "ABC Corp", email: "john.smith@example.com", phone: "(555) 123-4567", payment_type: "stripe", payment_status: "paid" },
    { name: "Jane Doe", company: "XYZ Inc", email: "jane.doe@example.com", phone: "(555) 234-5678", payment_type: "pay_on_day", payment_status: "unpaid" },
    { name: "Bob Johnson", company: "Acme LLC", email: "bob.johnson@example.com", phone: "(555) 345-6789", payment_type: "stripe", payment_status: "paid" },
    { name: "Alice Williams", company: "Tech Solutions", email: "alice.williams@example.com", phone: "(555) 456-7890", payment_type: "pay_on_day", payment_status: "unpaid" },
    { name: "Charlie Brown", company: "Golf Pros", email: "charlie.brown@example.com", phone: "(555) 567-8901", payment_type: "stripe", payment_status: "paid" },
    { name: "Diana Martinez", company: "Airport Services", email: "diana.martinez@example.com", phone: "(555) 678-9012", payment_type: "pay_on_day", payment_status: "unpaid" },
    { name: "Edward Lee", company: "Pacific Airlines", email: "edward.lee@example.com", phone: "(555) 789-0123", payment_type: "stripe", payment_status: "paid" },
    { name: "Fiona Garcia", company: "Island Tours", email: "fiona.garcia@example.com", phone: "(555) 890-1234", payment_type: "stripe", payment_status: "unpaid" },
  ]

  sample_golfers.each do |attrs|
    golfer = Golfer.find_or_create_by!(email: attrs[:email]) do |g|
      g.tournament = tournament
      g.name = attrs[:name]
      g.company = attrs[:company]
      g.phone = attrs[:phone]
      g.payment_type = attrs[:payment_type]
      g.payment_status = attrs[:payment_status]
      g.waiver_accepted_at = Time.current
      g.registration_status = "confirmed"
      g.address = "123 Main St, City, State 12345"
    end
    puts "Created golfer: #{golfer.name}"
  end

  # Create some groups
  puts "Creating sample groups..."
  2.times do |i|
    group = Group.find_or_create_by!(group_number: i + 1, tournament: tournament) do |g|
      g.hole_number = i + 1
    end
    puts "Created group #{group.group_number} at hole #{group.hole_number}"
  end

  # Assign some golfers to groups
  puts "Assigning golfers to groups..."
  golfers = Golfer.unassigned.limit(8)
  groups = Group.where(tournament: tournament)

  golfers.each_with_index do |golfer, index|
    group = groups[index / 4]
    if group && !group.full?
      group.add_golfer(golfer)
      puts "Added #{golfer.name} to Group #{group.group_number}"
    end
  end
end

puts "Seeding complete!"
