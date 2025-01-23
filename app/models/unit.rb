class Unit < ApplicationRecord
  belongs_to :property, counter_cache: true
  has_many :tenants
  has_many :lease_agreements, dependent: :destroy
  has_many :rents, dependent: :destroy
  
  enum status: {
    available_for_rent: 'available_for_rent',
    available_for_selling: 'available_for_selling',
    sold: 'sold',
    not_available: 'not_available'
  }

  validates :unit_number, presence: true
  validates :floor, presence: true, numericality: { only_integer: true }
  validates :selling_rate, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :status, presence: true
  
  after_save :update_property_units_count
  after_destroy :update_property_units_count

  def self.ransackable_associations(auth_object = nil)
    ["property"]
  end
  def self.ransackable_attributes(auth_object = nil)
    %w[
      created_at 
      floor 
      id 
      id_value 
      property_id 
      selling_rate 
      status 
      unit_number 
      updated_at
    ]
  end
  def generate_rent
    rent_due_date = lease_agreement&.rent_due_date || Date.today.beginning_of_month
    
    if rents.where(month: rent_due_date).exists?
      { success: false, message: "Rent for #{rent_due_date.strftime('%B %Y')} is already generated." }
    else
      rents.create!(
        amount: lease_agreement.rent_amount,
        month: rent_due_date,
        tenant: active_tenant 
      )
      { success: true, message: "Rent for #{rent_due_date.strftime('%B %Y')} generated successfully." }
    end
  end

  def active_tenant
    tenants.find_by(active: true)
  end
  
  private
  
  def only_one_active_tenant
    if tenants.where(active: true).count > 1
      errors.add(:base, "Only one active tenant is allowed per unit.")
    end
  end

  def update_property_units_count
    property.update_units_count
  end
end