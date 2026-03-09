# Demo seed for Make-A-Wish committee to explore the GIAA interface
# Uses all fake data — no proprietary airport tournament data

puts "🌱 Seeding GIAA Demo for Make-A-Wish committee..."

# Create settings
setting = Setting.find_or_create_by!(id: 1) do |s|
  s.max_capacity = 144
  s.admin_email = "demo@shimizu-technology.com"
end
puts "✅ Settings created (capacity: #{setting.max_capacity})"

# Create admin
admin = Admin.find_or_create_by!(email: "shimizutechnology@gmail.com") do |a|
  a.name = "Leon Shimizu"
  a.role = "admin"
end
puts "✅ Admin created: #{admin.email}"

# Also add Jerry as admin
jerry = Admin.find_or_create_by!(email: "jerry.shimizutechnology@gmail.com") do |a|
  a.name = "Jerry"
  a.role = "admin"
end
puts "✅ Admin created: #{jerry.email}"

# Create demo tournament
tournament = Tournament.find_or_create_by!(name: "Island Charity Golf Classic") do |t|
  t.year = 2026
  t.edition = "3rd Annual"
  t.event_date = Date.new(2026, 5, 10)
  t.registration_time = "7:00 AM"
  t.start_time = "8:00 AM Shotgun Start"
  t.max_capacity = 144
  t.reserved_slots = 0
  t.entry_fee = 15000 # $150.00
  t.employee_entry_fee = 7500 # $75.00
  t.registration_open = true
  t.status = "open"
  t.location_name = "Pacific Island Country Club"
  t.location_address = "123 Fairway Drive, Guam"
  t.format_name = "Two-Person Scramble"
  t.fee_includes = "Green Fee, Cart, Lunch, Ditty Bag, Awards Banquet"
  t.checks_payable_to = "Island Charity Foundation"
  t.contact_name = "Demo Admin"
  t.contact_phone = "(671) 555-0100"
end
puts "✅ Tournament created: #{tournament.name}"

# Demo golfer data — all fake names
demo_golfers = [
  # Paid golfers (checked in)
  { name: "Michael Santos", company: "Pacific Motors", email: "m.santos@example.com", phone: "(671) 555-0101", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "David Cruz", company: "Pacific Motors", email: "d.cruz@example.com", phone: "(671) 555-0102", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "James Reyes", company: "Island Insurance", email: "j.reyes@example.com", phone: "(671) 555-0103", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "Robert Taitano", company: "Island Insurance", email: "r.taitano@example.com", phone: "(671) 555-0104", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "William Perez", company: "Guam Power", email: "w.perez@example.com", phone: "(671) 555-0105", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "Thomas Mendiola", company: "Guam Power", email: "t.mendiola@example.com", phone: "(671) 555-0106", payment_type: "pay_on_day", payment_status: "paid", checked_in: true },
  { name: "Richard Borja", company: "Harbor Logistics", email: "r.borja@example.com", phone: "(671) 555-0107", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "Joseph Flores", company: "Harbor Logistics", email: "j.flores@example.com", phone: "(671) 555-0108", payment_type: "stripe", payment_status: "paid", checked_in: true },

  # Paid golfers (NOT checked in)
  { name: "Daniel Camacho", company: "Oceanic Bank", email: "d.camacho@example.com", phone: "(671) 555-0109", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Steven Ada", company: "Oceanic Bank", email: "s.ada@example.com", phone: "(671) 555-0110", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Paul Quinata", company: "Reef Construction", email: "p.quinata@example.com", phone: "(671) 555-0111", payment_type: "pay_on_day", payment_status: "paid", checked_in: false },
  { name: "Mark Duenas", company: "Reef Construction", email: "m.duenas@example.com", phone: "(671) 555-0112", payment_type: "pay_on_day", payment_status: "paid", checked_in: false },
  { name: "Andrew Blas", company: "Tradewinds Corp", email: "a.blas@example.com", phone: "(671) 555-0113", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "George Manibusan", company: "Tradewinds Corp", email: "g.manibusan@example.com", phone: "(671) 555-0114", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Christopher Leon Guerrero", company: "Pacific Air", email: "c.leonguerrero@example.com", phone: "(671) 555-0115", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Brian Unpingco", company: "Pacific Air", email: "b.unpingco@example.com", phone: "(671) 555-0116", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Kevin Salas", company: "Sun Motors", email: "k.salas@example.com", phone: "(671) 555-0117", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Ryan Pangelinan", company: "Sun Motors", email: "r.pangelinan@example.com", phone: "(671) 555-0118", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Edward Sablan", company: "Triple Star", email: "e.sablan@example.com", phone: "(671) 555-0119", payment_type: "pay_on_day", payment_status: "paid", checked_in: false },
  { name: "Anthony Charfauros", company: "Triple Star", email: "a.charfauros@example.com", phone: "(671) 555-0120", payment_type: "pay_on_day", payment_status: "paid", checked_in: false },

  # Unpaid golfers
  { name: "Frank Paulino", company: "Guam Shipping", email: "f.paulino@example.com", phone: "(671) 555-0121", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Raymond Aguon", company: "Guam Shipping", email: "r.aguon@example.com", phone: "(671) 555-0122", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Dennis Castro", company: "Coral Insurance", email: "d.castro@example.com", phone: "(671) 555-0123", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Patrick Siguenza", company: "Coral Insurance", email: "p.siguenza@example.com", phone: "(671) 555-0124", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Jose Bautista", company: "Marianas Tech", email: "j.bautista@example.com", phone: "(671) 555-0125", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Peter Naputi", company: "Marianas Tech", email: "p.naputi@example.com", phone: "(671) 555-0126", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Carlos Rosario", company: "Sunset Realty", email: "c.rosario@example.com", phone: "(671) 555-0127", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Tony Cepeda", company: "Sunset Realty", email: "t.cepeda@example.com", phone: "(671) 555-0128", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },

  # Employee/comp golfers (paid at reduced rate)
  { name: "Alex Rivera", company: "Pacific Island CC", email: "a.rivera@example.com", phone: "(671) 555-0129", payment_type: "pay_on_day", payment_status: "paid", checked_in: false, is_employee: true },
  { name: "Maria Terlaje", company: "Pacific Island CC", email: "m.terlaje@example.com", phone: "(671) 555-0130", payment_type: "pay_on_day", payment_status: "paid", checked_in: false, is_employee: true },

  # Additional teams for volume
  { name: "Vincent Palomo", company: "GTA Teleguam", email: "v.palomo@example.com", phone: "(671) 555-0131", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Juan Tenorio", company: "GTA Teleguam", email: "j.tenorio@example.com", phone: "(671) 555-0132", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Manuel Quitugua", company: "Bank of the Islands", email: "m.quitugua@example.com", phone: "(671) 555-0133", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Roberto San Nicolas", company: "Bank of the Islands", email: "r.sannicolas@example.com", phone: "(671) 555-0134", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Luis Aguero", company: "Flame Tree BBQ", email: "l.aguero@example.com", phone: "(671) 555-0135", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "Felix Mantanona", company: "Flame Tree BBQ", email: "f.mantanona@example.com", phone: "(671) 555-0136", payment_type: "stripe", payment_status: "paid", checked_in: true },
  { name: "Henry Lujan", company: "Guam Waterworks", email: "h.lujan@example.com", phone: "(671) 555-0137", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Oscar Benavente", company: "Guam Waterworks", email: "o.benavente@example.com", phone: "(671) 555-0138", payment_type: "stripe", payment_status: "paid", checked_in: false },
  { name: "Larry Toves", company: "Chamorro Village Co", email: "l.toves@example.com", phone: "(671) 555-0139", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
  { name: "Nelson Quenga", company: "Chamorro Village Co", email: "n.quenga@example.com", phone: "(671) 555-0140", payment_type: "pay_on_day", payment_status: "unpaid", checked_in: false },
]

demo_golfers.each do |attrs|
  is_employee = attrs.delete(:is_employee) || false
  checked_in = attrs.delete(:checked_in)

  golfer = Golfer.find_or_create_by!(email: attrs[:email]) do |g|
    g.tournament = tournament
    g.name = attrs[:name]
    g.company = attrs[:company]
    g.phone = attrs[:phone]
    g.payment_type = attrs[:payment_type]
    g.payment_status = attrs[:payment_status]
    g.waiver_accepted_at = Time.current - rand(1..14).days
    g.registration_status = "confirmed"
    g.address = "#{rand(100..999)} Demo St, Tamuning, GU 96913"
    g.is_employee = is_employee if g.respond_to?(:is_employee=)
    g.checked_in_at = Time.current if checked_in
    g.paid_at = Time.current - rand(1..10).days if attrs[:payment_status] == "paid"
  end
end
puts "✅ Created #{demo_golfers.size} demo golfers"

# Create groups (9 holes × 2 = 18 groups for a scramble)
puts "Creating groups and assigning golfers..."
paid_golfers = Golfer.where(tournament: tournament, payment_status: "paid").order(:id)
group_number = 1

paid_golfers.each_slice(4) do |golfer_batch|
  group = Group.find_or_create_by!(group_number: group_number, tournament: tournament) do |g|
    g.hole_number = ((group_number - 1) % 18) + 1
  end

  golfer_batch.each do |golfer|
    begin
      group.add_golfer(golfer)
    rescue => e
      # If add_golfer method doesn't exist or fails, assign directly
      golfer.update(group: group) if golfer.respond_to?(:group=)
    end
  end

  group_number += 1
end
puts "✅ Created #{group_number - 1} groups with golfers assigned"

# Create some activity logs for realism
if defined?(ActivityLog)
  [
    { action: "golfer_registered", details: "Michael Santos registered online", admin_id: nil },
    { action: "golfer_registered", details: "David Cruz registered online", admin_id: nil },
    { action: "payment_received", details: "Payment received from Pacific Motors (check #4521)", admin_id: admin.id },
    { action: "golfer_checked_in", details: "Michael Santos checked in at registration desk", admin_id: admin.id },
    { action: "group_assigned", details: "Group 1 assigned to Hole 1", admin_id: admin.id },
    { action: "golfer_registered", details: "Frank Paulino registered (pay on day)", admin_id: nil },
    { action: "settings_updated", details: "Registration capacity updated to 144", admin_id: admin.id },
  ].each do |log_attrs|
    ActivityLog.create!(
      action: log_attrs[:action],
      details: log_attrs[:details],
      admin_id: log_attrs[:admin_id],
      tournament: tournament,
      created_at: Time.current - rand(1..7).days
    )
  end
  puts "✅ Created activity logs"
end

puts ""
puts "=" * 60
puts "🎉 GIAA Demo seeding complete!"
puts "=" * 60
puts ""
puts "Tournament: #{tournament.name} (#{tournament.edition})"
puts "Date: #{tournament.event_date}"
puts "Location: #{tournament.location_name}"
puts "Golfers: #{Golfer.where(tournament: tournament).count}"
puts "  - Paid: #{Golfer.where(tournament: tournament, payment_status: 'paid').count}"
puts "  - Unpaid: #{Golfer.where(tournament: tournament, payment_status: 'unpaid').count}"
puts "  - Checked in: #{Golfer.where(tournament: tournament).where.not(checked_in_at: nil).count}"
puts "Groups: #{Group.where(tournament: tournament).count}"
puts ""
puts "Admin login: shimizutechnology@gmail.com (via Clerk)"
puts "=" * 60
