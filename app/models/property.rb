# app/models/property.rb
class Property < ApplicationRecord
  has_many :units, dependent: :destroy
  has_many :tenants, through: :units

  enum property_type: {
    apartment: 'apartment',
    house: 'house', 
    condo: 'condo',
    duplex: 'duplex',
    townhouse: 'townhouse',
    commercial: 'commercial',
    villa: 'villa',
    loft: 'loft',
    farm: 'farm'
  }

  validates :name, :address, :city, :country, :property_type, presence: true
  validates :zip_code, format: { 
    with: /\A\d{5}(-\d{4})?\z/, 
    message: "should be in 12345 or 12345-6789 format",
    allow_blank: true
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[name address property_type city country]
  end

 
  def update_units_count
    update(units_count: units.count)
  end
end