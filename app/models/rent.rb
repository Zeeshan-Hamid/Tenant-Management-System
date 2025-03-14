class Rent < ApplicationRecord
  belongs_to :tenant
  belongs_to :unit

  validates :tenant, :unit, :amount, :due_date, :month, presence: true
  validates :status, inclusion: { in: %w[pending paid overdue] }

  # Enum for status
  enum status: { pending: 'pending', paid: 'paid', overdue: 'overdue' }

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :payment_date, presence: true
  validates :status, inclusion: { in: %w[pending paid overdue], message: "%{value} is not a valid status" }

  # Allowlisted associations for Ransack
  def self.ransackable_associations(auth_object = nil)
    ["tenant", "unit"] # Add associations you want to be searchable
  end

  # Allowlisted attributes for Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["amount", "due_date", "payment_date", "status", "created_at", "updated_at", "is_advance"]
  end

  # Allow Ransack to search enum attributes
  def self.ransackable_scopes(auth_object = nil)
    [:status_eq] # Allow searching by exact enum value
  end

  after_create :update_tenant_balance

  # Example method to mark rent as paid
  def mark_as_paid
    if advance_credit > 0
      if amount <= advance_credit
        deduct_advance(amount) # Deduct from advance credit
        update(status: 'paid')
      else
        # If the payment exceeds advance credit, charge the balance to the tenant
        balance_amount = amount - advance_credit
        deduct_advance(advance_credit)
        add_rent_payment(balance_amount)
        update(status: 'paid')
      end
    else
      # No advance credit, treat as regular payment
      add_rent_payment(amount)
      update(status: 'paid')
    end
  end
  

  private

  def update_tenant_balance
    if status == 'paid'
      if is_advance
        tenant.add_advance_payment(amount)
      else
        tenant.add_rent_payment(amount)
      end
    end
  end
end
