class Tenant < ApplicationRecord
  belongs_to :unit
  has_one :lease_agreement, dependent: :destroy

  has_many :rents, dependent: :destroy

  accepts_nested_attributes_for :lease_agreement
  
  after_initialize :set_default_balance, if: :new_record?

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :advance_credit, numericality: { greater_than_or_equal_to: 0 }
  after_create :generate_initial_rent

  

  

  def self.ransackable_attributes(auth_object = nil)
    # List of attributes you want to be searchable
    ["active", "advance_credit", "balance", "created_at", "email", "id", "id_value", "name", "phone", "unit_id", "updated_at"]
  end

  def add_rent_payment(amount)
    self.balance -= amount
    save
  end

  def add_advance_payment(amount)
    self.advance_credit += amount
    save
  end

  def deduct_advance(amount)
    self.advance_credit -= amount
    save
  end

  def refund_payment(amount)
    self.balance += amount
    save
  end

  def activate
    update(active: true)
  end

  # Method to deactivate the tenant
  def deactivate
    update!(active: false)
  end

  private
  def set_default_balance
    self.balance ||= 0.0
    self.advance_credit ||= 0.0

  end
  def generate_initial_rent
    # Ensure the tenant has a lease agreement and unit
    if lease_agreement.present? && unit.present?
      rents.create!(
        amount: lease_agreement.rent_amount,
        due_date: Date.today + 10.days, # Due 10 days from today
        payment_date: nil, # Will be set when marked as paid
        month: Date.today.beginning_of_month,
        status: 'pending',
        unit: unit
      )
    else
      Rails.logger.error "Failed to generate initial rent for Tenant #{id}: Missing lease agreement or unit."
    end
  end

  def ensure_single_active_tenant
    if active && Tenant.where(unit_id: unit_id, active: true).exists?
      errors.add(:active, "This unit already has an active tenant.")
    end
  end
end
