# frozen_string_literal: true

class LeaseAgreement < ApplicationRecord
  include PublicActivity::Model
  tracked owner: lambda { |controller, _model|
    controller.try(:current_admin_user) || controller.try(:current_user) if controller.present?
  }

  belongs_to :tenant
  belongs_to :property

  has_many :lease_agreement_units, dependent: :destroy
  has_many :user_lease_agreements, dependent: :destroy
  has_many :units, through: :lease_agreement_units
  has_many :rents, dependent: :destroy

  accepts_nested_attributes_for :tenant

  enum increment_frequency: { quarterly: "quarterly", yearly: "yearly" }
  enum increment_type: { fixed: "fixed", percentage: "percentage" }
  enum status: { active: "Active", deactivate: "Deactivated" }

  validates :start_date, :end_date, :rent_amount, :security_deposit, presence: true
  validates :increment_frequency, :increment_type, presence: true
  validates :rent_amount, numericality: { greater_than: 0 }
  validates :security_deposit, numericality: { greater_than: 0 }
  validates :annual_increment, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :end_date, comparison: { greater_than: :start_date }
  validate  :validate_security_deposit
  validate  :annual_increment_within_limit

  after_create :schedule_rent_generation
  after_update :destroy_rents_if_deactivated, if: :saved_change_to_status?

  scope :active_agreements, -> { where(status: status_value_for(:active)) }
  scope :deactivated_agreements, -> { where(status: status_value_for(:deactivate)) }

  def self.status_value_for(status_key)
    statuses[status_key]
  end

  def self.increment_frequency_value_for(frequency_key)
    increment_frequencies[frequency_key]
  end

  def self.increment_type_value_for(type_key)
    increment_types[type_key]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[tenant]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[start_date end_date rent_amount security_deposit annual_increment increment_frequency
       increment_type]
  end

  def next_payment_due_date(last_payment_date)
    calculate_next_payment_date(last_payment_date)
  rescue ArgumentError
    (last_payment_date + 1.month).end_of_month
  end

  def calculate_new_rent(current_rent)
    increment_amount = calculate_increment_amount(current_rent)
    apply_increment_based_on_frequency(current_rent, increment_amount)
  end

  def to_s
    "Lease Agreement for Tenant: #{tenant.try(:name)}"
  end

  private

  def calculate_next_payment_date(last_payment_date)
    case increment_frequency
    when self.class.increment_frequency_value_for(:quarterly) then last_payment_date + 3.months
    when self.class.increment_frequency_value_for(:yearly)    then last_payment_date + 1.year
    else                                                           last_payment_date + 30.days
    end
  end

  def calculate_increment_amount(current_rent)
    case increment_type
    when self.class.increment_type_value_for(:fixed)      then annual_increment.to_f
    when self.class.increment_type_value_for(:percentage) then current_rent * (annual_increment.to_f / 100.0)
    else                                                       0
    end
  end

  def apply_increment_based_on_frequency(current_rent, increment_amount)
    case increment_frequency
    when self.class.increment_frequency_value_for(:quarterly) then current_rent + (increment_amount / 4)
    when self.class.increment_frequency_value_for(:yearly)    then current_rent + increment_amount
    else                                                           current_rent
    end
  end

  def validate_security_deposit
    return unless security_deposit.present? && rent_amount.present? && security_deposit < rent_amount

    errors.add(:security_deposit, "must be at least one month's rent")
  end

  def annual_increment_within_limit
    return unless increment_type == self.class.increment_type_value_for(:percentage) &&
                  annual_increment.present? &&
                  annual_increment > 100

    errors.add(:annual_increment, "must not exceed 100 when increment type is percentage")
  end

  def schedule_rent_generation
    return if deactivate?

    effective_start     = Date.current
    total_days_in_month = effective_start.end_of_month.day
    remaining_days      = (effective_start.end_of_month - effective_start).to_i + 1
    pro_rata_rent       = calculate_pro_rata_rent(effective_start, total_days_in_month, remaining_days)

    create_initial_rent(effective_start, pro_rata_rent)
  end

  def calculate_pro_rata_rent(effective_start, total_days_in_month, remaining_days)
    raw_rent = (rent_amount / total_days_in_month.to_f) * remaining_days
    (raw_rent / 10.0).ceil * 10
  end

  def create_initial_rent(effective_start, pro_rata_rent)
    rent_name = generate_rent_name(effective_start)
    rents.create!(
      amount: pro_rata_rent,
      payment_date: effective_start,
      due_date: effective_start + 10.days,
      status: "pending",
      rent_name: rent_name
    )
  end

  def generate_rent_name(date)
    # Format: <first three letters of month><last two digits of year>
    month_abbr = date.strftime("%b").downcase
    year_digits = date.strftime("%y")
    "#{month_abbr}#{year_digits}"
  end

  def destroy_rents_if_deactivated
    rents.destroy_all if deactivate?
  end
end
