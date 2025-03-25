# frozen_string_literal: true

class Property < ApplicationRecord
  include PublicActivity::Model
  tracked owner: lambda { |controller, _model|
    controller.try(:current_admin_user) || controller.try(:current_user) if controller.present?
  }

  has_many :units, dependent: :destroy
  has_many :tenants, through: :units
  has_many :user_properties, dependent: :destroy
  has_many :users, through: :user_properties
  has_many :lease_agreements, dependent: :destroy

  enum property_type: {
    apartment: 0,
    house: 1,
    condo: 2,
    duplex: 3,
    townhouse: 4,
    villa: 5,
    bungalow: 6,
    penthouse: 7,
    studio_apartment: 8,
    loft: 9,
    cottage: 10,
    office_building: 11,
    retail_space: 12,
    warehouse: 13,
    industrial_property: 14,
    co_working_space: 15,
    restaurant_cafe: 16,
    hotel_motel: 17,
    mall: 18,
    farm: 19,
    school_university: 20,
    hospital_clinic: 21,
    nursing_home_assisted_living: 22,
    stadium_arena: 23,
    convention_center: 24,
    residential_land: 25,
    commercial_land: 26,
    industrial_land: 27,
    recreational_land: 28
  }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :address, :city, :country, :property_type, presence: true

  before_destroy :ensure_units_not_on_rent

  def self.ransackable_attributes(_auth_object = nil)
    %w[name address property_type city country]
  end

  def update_units_count
    update(units_count: units.count)
  end

  private

  def ensure_units_not_on_rent
    return unless units.on_rent.exists?

    errors.add(:base, "Cannot delete property because one or more units are currently on rent.")
    throw(:abort)
  end
end
