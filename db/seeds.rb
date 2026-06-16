# Seeds for Brooke & Maisy Interior Designs
# Run with: rails db:seed

# Clear existing users
User.destroy_all

# Admin user (Amanda - the business owner)
admin = User.create!(
  email: 'amanda@brookeandmaisy.com',
  name: 'Amanda',
  password: 'Password123!',
  password_confirmation: 'Password123!',
  role: 'admin'
)
puts "Created admin: #{admin.email}"

# Sample client users
clients = [
  { email: 'sarah.johnson@email.com', name: 'Sarah Johnson' },
  { email: 'michael.chen@email.com',  name: 'Michael Chen' },
  { email: 'emily.davis@email.com',   name: 'Emily Davis' },
  { email: 'james.wilson@email.com',  name: 'James Wilson' },
  { email: 'lisa.brown@email.com',    name: 'Lisa Brown' }
]

created_clients = clients.map do |client_data|
  client = User.create!(
    email: client_data[:email],
    name: client_data[:name],
    password: 'Password123!',
    password_confirmation: 'Password123!',
    role: 'client'
  )
  puts "Created client: #{client.email}"
  client
end

# Sample projects + updates for the first two clients (demo data)
sarah = created_clients[0]
michael = created_clients[1]

p1 = sarah.projects.create!(
  title: "Lakefront Living Room Refresh", status: "design",
  address: "123 Oak Street, Rock Hill, SC",
  description: "Coastal-modern refresh of the main living space with new flooring and window treatments."
)
p1.project_updates.create!(body: "Initial consultation complete. Mood board shared.", visible_to_client: true)
p1.project_updates.create!(body: "Internal note: awaiting flooring vendor quote.", visible_to_client: false)
p1.project_updates.create!(body: "Paint palette finalized — warm whites with olive accents.", visible_to_client: true)

sarah.projects.create!(
  title: "Primary Bedroom", status: "discovery",
  address: "123 Oak Street, Rock Hill, SC",
  description: "Calm, restful primary suite redesign."
)

michael.projects.create!(
  title: "Home Office Build-Out", status: "in_progress",
  address: "456 Maple Ave, Fort Mill, SC",
  description: "Dedicated work-from-home office with built-in shelving."
)

puts "\n=== Seed Summary ==="
puts "Admin users: #{User.where(role: 'admin').count}"
puts "Client users: #{User.where(role: 'client').count}"
puts "Projects: #{Project.count}"
puts "Updates: #{ProjectUpdate.count}"
