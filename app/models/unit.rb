class Unit < ApplicationRecord
  belongs_to :property, counter_cache: true
  has_many :tenants

  has_many :lease_agreements, dependent: :destroy
  has_many :rents, dependent: :destroy
  
  after_save :update_property_units_count
  after_destroy :update_property_units_count

  

  enum status: {
    available_for_rent: 0,
    available_for_selling: 1,
    sold: 2,  # New status for sold units
    not_available: 3
  }

  validates :unit_number, presence: true
  validates :floor, presence: true, numericality: { only_integer: true }
  validates :selling_rate, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :status, presence: true
  
  validate :only_one_active_tenant

  def self.ransackable_associations(auth_object = nil)
    ["property"]
  end
 
  def generate_rent
    rent_due_date = lease_agreement&.rent_due_date || Date.today.beginning_of_month

    # Check if rent for the month is already generated
    if rents.where(month: rent_due_date).exists?
      { success: false, message: "Rent for #{rent_due_date.strftime('%B %Y')} is already generated." }
    else
      rents.create!(
        amount: lease_agreement.rent_amount,
        month: rent_due_date,
        tenant: active_tenant # Assuming active_tenant method returns the current tenant
      )
      { success: true, message: "Rent for #{rent_due_date.strftime('%B %Y')} generated successfully." }
    end
  end

  def active_tenant
    tenants.find_by(active: true) # Adjust the condition as needed based on your tenant model
  end
  
  private
  
  def only_one_active_tenant
    if tenants.present? && tenant.active && Tenant.where(unit_id: id, active: true).exists?
      errors.add(:tenant, "Only one active tenant is allowed per unit.")
    end
  end

  def update_property_units_count
    property.update_units_count
  end
end
