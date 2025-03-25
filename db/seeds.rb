# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?

# Clear existing data (optional, be careful with this in production)
Tenant.destroy_all
LeaseAgreement.destroy_all
Property.destroy_all
Unit.destroy_all


# Create sample properties
properties = Property.create([
  { name: "Property A", address: "123 Main St", property_type: "apartment", description: "A lovely apartment complex" },
  { name: "Property B", address: "456 Elm St", property_type: "condo", description: "Beautiful condos available" },
  { name: "Property C", address: "789 Oak St", property_type: "townhouse", description: "Spacious townhouses for rent" },
  { name: "Property D", address: "101 Pine St", property_type: "duplex", description: "Charming duplex for families" }
])

# Generate random units for each property
properties.each do |property|
  # Randomly determine the number of floors (3 to 4)
  number_of_floors = rand(3..4)

  (1..number_of_floors).each do |floor_number|
    # Randomly determine the number of units per floor (5 to 8)
    number_of_units = rand(5..8)

    (1..number_of_units).each do |unit_number|
      Unit.create!(
        property: property,
        floor: floor_number,
        unit_number: "Unit #{floor_number}-#{unit_number}",
        selling_rate: rand(100000..500000), # Random selling rate for units
        status: [ "available_for_rent", "available_for_selling", "sold" ].sample,
        # Add any other attributes required for the Unit model
      )
    end
  end
end

puts "Seeded #{properties.count} properties with random units. #{Unit.count} units created."




50.times do
  # Randomly assign a property and unit for the lease agreement
  property = properties.sample
  unit = property.units.joins(:tenants).where(tenants: { active: false }).sample
  unit ||= property.units.sample
  puts "#{unit.unit_number} - #{unit.active_tenant.present? ? unit.active_tenant.name : 'No tenant'}"
  next if unit.active_tenant.present?

  # Ensure you have units associated with the property

  tenant_name = Faker::Name.name
  tenant_phone = Faker::PhoneNumber.phone_number
  tenant_email = Faker::Internet.email

  tenant = Tenant.create!(
    unit: unit,
    name: tenant_name,
    phone: tenant_phone,
    email: tenant_email,
    active: true
  )



  LeaseAgreement.create!(
    tenant: tenant,
    unit: unit,
    start_date: Faker::Date.between(from: 2.days.ago, to: Date.today),
    end_date: Faker::Date.between(from: Date.today, to: Date.today + 1.year),
    rent_amount: Faker::Number.decimal(l_digits: 3, r_digits: 2), # Random rent amount
    security_deposit: Faker::Number.decimal(l_digits: 2, r_digits: 2), # Random security deposit
    status: [ 'active', 'inactive' ].sample, # Random status
    annual_increment: Faker::Number.between(from: 1, to: 10), # Random increment between 1 and 10
    increment_frequency: [ 'quarterly', 'yearly' ].sample, # Random frequency
    increment_type: [ 'fixed', 'percentage' ].sample # Random increment type
  )
end

puts "Created #{Tenant.count} tenants and #{LeaseAgreement.count} lease agreements."
