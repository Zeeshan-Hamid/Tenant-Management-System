class Tenant < ApplicationRecord
  belongs_to :unit
  has_one :lease_agreement, dependent: :destroy

  has_many :rents, dependent: :destroy

  accepts_nested_attributes_for :lease_agreement
  
  after_initialize :set_default_balance, if: :new_record?

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :advance_credit, numericality: { greater_than_or_equal_to: 0 }


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

  def ensure_single_active_tenant
    if active && Tenant.where(unit_id: unit_id, active: true).exists?
      errors.add(:active, "This unit already has an active tenant.")
    end
  end
end
