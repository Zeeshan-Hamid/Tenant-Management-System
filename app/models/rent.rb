class Rent < ApplicationRecord
  belongs_to :unit
  belongs_to :tenant

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :status, inclusion: { in: %w[paid pending overdue], message: "%{value} is not a valid status" }

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
