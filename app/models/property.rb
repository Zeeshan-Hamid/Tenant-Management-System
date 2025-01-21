class Property < ApplicationRecord
  has_many :units, dependent: :destroy
  has_many :tenants, through: :units


  enum property_type: {
    apartment: 0,
    house: 1,
    condo: 2,
    duplex: 3,
    townhouse: 4,
    commercial: 5,
    villa: 6,
    loft:7,
    faram: 8

  }

  validates :name, presence: true
  validates :property_type, presence: true

  def self.ransackable_attributes(auth_object = nil)
    %w[name address property_type]
  end

  def update_units_count
    self.update_column(:units_count, units.size)
  end
end
