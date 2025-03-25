class Rent < ApplicationRecord
  include PublicActivity::Model
  tracked owner: lambda { |controller, _model|
    controller.try(:current_admin_user) || controller.try(:current_user) if controller.present?
  }, parameters: lambda { |controller, _model|
    owner = controller.present? ? (controller.try(:current_admin_user) || controller.try(:current_user)) : nil
    { owner_name: owner.try(:name) }
  }

  belongs_to :lease_agreement
  delegate :tenant, to: :lease_agreement

  validates :amount, :payment_date, presence: true
  validates :status, inclusion: { in: %w[paid pending overdue] }

  enum payment_method: { cash: "cash", online: "online" }

  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :overdue, -> { where(status: "overdue") }

  after_create :update_tenant_balance
  after_create :schedule_next_rent, if: -> { status == "paid" }

  def self.ransackable_associations(_auth_object = nil)
    %w[lease_agreement]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[lease_agreement_id amount created_at id is_advance payment_date status due_date rent_name]
  end

  def mark_as_paid
    self.due_date ||= payment_date + 10.days
    if update(status: "paid")
      Rails.logger.info "Rent ##{id} successfully marked as paid."

      # Explicitly call schedule_next_rent since callbacks don't trigger on update
      schedule_next_rent

      true
    else
      Rails.logger.error "Failed to mark Rent ##{id} as paid: #{errors.full_messages.join(', ')}"
      false
    end
  rescue StandardError => e
    Rails.logger.error "Exception in mark_as_paid: #{e.message}"
    false
  end

  def schedule_next_rent
    next_payment_date = payment_date.next_month.beginning_of_month
    return if Rent.exists?(lease_agreement: lease_agreement, payment_date: next_payment_date)

    # Generate rent name for next month
    next_rent_name = generate_rent_name(next_payment_date)
    Rails.logger.info "Generated rent name for next month: #{next_rent_name}"

    Rent.create!(
      lease_agreement: lease_agreement,
      amount: amount,
      payment_date: next_payment_date,
      status: "pending",
      due_date: next_payment_date + 10.days,
      rent_name: next_rent_name
    )
  end

  def generate_rent_name(date)
    # Format: <first three letters of month><last two digits of year>
    month_abbr = date.strftime("%b").downcase
    year_digits = date.strftime("%y")
    "#{month_abbr}#{year_digits}"
  end

  private

  def update_tenant_balance
    return unless status == "paid"

    if is_advance
      lease_agreement.tenant.add_advance_payment(amount)
    else
      lease_agreement.tenant.add_rent_payment(amount)
    end
  end
end
