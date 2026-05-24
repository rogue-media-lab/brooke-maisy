# Seeds for Brooke & Maisy Interior Designs
# Run with: rails db:seed

# Clear existing users
User.destroy_all

# Admin user (Amanda - the business owner)
admin = User.create!(
  email: 'amanda@brookeandmaisy.com',
  password: 'Password123!',
  password_confirmation: 'Password123!',
  role: 'admin'
)
puts "Created admin: #{admin.email}"

# Sample client users
clients = [
  {
    email: 'sarah.johnson@email.com',
    name: 'Sarah Johnson',
    phone: '(803) 555-0101',
    address: '123 Oak Street, Rock Hill, SC 29730'
  },
  {
    email: 'michael.chen@email.com',
    name: 'Michael Chen',
    phone: '(803) 555-0102',
    address: '456 Maple Ave, Fort Mill, SC 29708'
  },
  {
    email: 'emily.davis@email.com',
    name: 'Emily Davis',
    phone: '(803) 555-0103',
    address: '789 Pine Road, Waxhaw, NC 28173'
  },
  {
    email: 'james.wilson@email.com',
    name: 'James Wilson',
    phone: '(803) 555-0104',
    address: '321 Cedar Lane, Marvin, NC 28173'
  },
  {
    email: 'lisa.brown@email.com',
    name: 'Lisa Brown',
    phone: '(803) 555-0105',
    address: '654 Birch Blvd, Weddington, NC 28104'
  }
]

clients.each do |client_data|
  client = User.create!(
    email: client_data[:email],
    password: 'Password123!',
    password_confirmation: 'Password123!',
    role: 'client'
  )
  puts "Created client: #{client.email}"
end

puts "\n=== Seed Summary ==="
puts "Admin users: #{User.where(role: 'admin').count}"
puts "Client users: #{User.where(role: 'client').count}"
puts "Total users: #{User.count}"
