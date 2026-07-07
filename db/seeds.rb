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

# Trade Partners — seed existing hardcoded data
TradePartner.destroy_all

TradePartner.create!(
  name: "Mike's Painting",
  trade_type: "painter",
  phone: "(555) 234-5678",
  description: "Specializes in interior repaints, cabinet painting, and color consultations.",
  years_experience: 8,
  rating: 4.9,
  jobs_referred: 12,
  display_order: 1
)

TradePartner.create!(
  name: "Carolina Custom Carpentry",
  trade_type: "carpenter",
  phone: "(555) 345-6789",
  description: "Custom cabinetry, built-in shelving, and millwork for high-end renovations.",
  years_experience: 12,
  rating: 5.0,
  jobs_referred: 8,
  display_order: 2
)

TradePartner.create!(
  name: "Spark Electric",
  trade_type: "electrician",
  phone: "(555) 456-7890",
  description: "Licensed electrician specializing in lighting design, panel upgrades, and smart home wiring.",
  years_experience: 6,
  rating: 4.8,
  jobs_referred: 5,
  display_order: 3
)

TradePartner.create!(
  name: "Pipes & Plumbers Co",
  trade_type: "plumber",
  phone: "(555) 567-8901",
  description: "Full-service plumbing for bathroom and kitchen renovations, water heater installation, and repairs.",
  years_experience: 10,
  rating: 4.7,
  jobs_referred: 3,
  display_order: 4
)

# Services — seed existing hardcoded data
Service.destroy_all

Service.create!(
  title: "Full Home Redesign",
  description: "Complete transformation of your living spaces with thoughtful layouts, curated furnishings, and cohesive design.",
  icon_name: "home",
  bullet_points: "Complete space planning\nFurniture selection & procurement\nColor palette development\nLighting design\nArt & accessory styling",
  display_order: 1
)

Service.create!(
  title: "Room Makeover",
  description: "Focus on a single room to maximize impact. Perfect for updating your living room, bedroom, or kitchen.",
  icon_name: "sparkles",
  bullet_points: "Space assessment\nFurniture layout optimization\nColor consultation\nDecor selection\nBudget planning",
  display_order: 2
)

Service.create!(
  title: "Color & Styling",
  description: "Color consultations, art arrangement, and finishing touches to bring your space to life.",
  icon_name: "paint",
  bullet_points: "Color palette creation\nPaint selection\nArt arrangement\nAccessory styling\nFinish selections",
  display_order: 3
)

puts "\n=== Seed Summary ==="
puts "Services: #{Service.count}"
puts "Trade Partners: #{TradePartner.count}"
puts "Admin users: #{User.where(role: 'admin').count}"
puts "Client users: #{User.where(role: 'client').count}"
puts "Projects: #{Project.count}"
puts "Updates: #{ProjectUpdate.count}"
