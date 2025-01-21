class LeaseAgreement < ApplicationRecord
  belongs_to :tenant
  belongs_to :unit

  # Validations
  validates :start_date, :end_date, :rent_amount, presence: true
  validates :end_date, comparison: { greater_than: :start_date }
  validates :annual_increment, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :increment_frequency, inclusion: { in: %w[quarterly yearly], message: "%{value} is not a valid frequency" }, allow_nil: true
  validates :increment_type, inclusion: { in: %w[fixed percentage], message: "%{value} is not a valid type" }, allow_nil: true
  validates :rent_amount, presence: true

  # Custom validation to ensure annual_increment does not exceed 100 if increment_type is percentage
  validate :annual_increment_within_limit, if: -> { increment_type == 'percentage' }
  validate :unit_id_matches_tenant

  #after_save :schedule_rent_generation


  private

  def schedule_rent_generation
    RentGeneratorWorker.perform_at(due_date, tenant.id)
  end

  def annual_increment_within_limit
    if annual_increment.present? && annual_increment > 100
      errors.add(:annual_increment, "must not exceed 100 when increment type is percentage")
    end
  end

  def unit_id_matches_tenant
    if tenant.present? && tenant.unit_id != unit_id
      errors.add(:unit_id, "must match the unit associated with the tenant")
    end
  end

  # Method to calculate the new rent based on the increment
  def calculate_new_rent(current_rent)
    case increment_type
    when 'fixed'
      increment_amount = annual_increment
    when 'percentage'
      increment_amount = (current_rent * (annual_increment / 100.0))
    else
      increment_amount = 0
    end

    case increment_frequency
    when 'quarterly'
      new_rent = current_rent + (increment_amount / 4)
    when 'yearly'
      new_rent = current_rent + increment_amount
    else
      new_rent = current_rent
    end
    new_rent
  end
end
