# frozen_string_literal: true

class Unit < ApplicationRecord
  include PublicActivity::Model
  tracked owner: lambda { |controller, _model|
    controller.try(:current_admin_user) || controller.try(:current_user) if controller.present?
  }

  belongs_to :property
  has_many :lease_agreement_units, dependent: :destroy
  has_many :lease_agreements, through: :lease_agreement_units

  enum status: {
    available_for_rent: 0,
    available_for_selling: 1,
    sold: 2,
    not_available: 3,
    on_rent: 4
  }

  validates :unit_number, presence: true,
                          uniqueness: { scope: :property_id, message: "Can't have same number for units of a Property" }
  validates :rental_rate, numericality: { greater_than: 0 }, allow_nil: true

  before_destroy :ensure_not_on_rent_and_active_lease_associations
  after_save :update_property_units_count

  def self.ransackable_attributes(_auth_object = nil)
    %w[id property_id unit_number floor square_footage rental_rate selling_rate status created_at
       updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[activities lease_agreement_units lease_agreements property]
  end

  def generate_rent(rent_due_date)
    if rents.where(month: rent_due_date).exists?
      { success: false,
        message: "Rent for #{rent_due_date.strftime('%B %Y')} is already generated." }
    else
      rents.create!(
        amount: lease_agreement.rent_amount,
        month: rent_due_date,
        tenant: active_tenant
      )
      { success: true,
        message: "Rent for #{rent_due_date.strftime('%B %Y')} generated successfully." }
    end
  end

  def active_tenant
    lease_agreements.active.first&.tenant
  end

  private

  def ensure_not_on_rent_and_active_lease_associations
    if on_rent?
      errors.add(:base, "Unit cannot be deleted because it is currently on rent.")
      throw(:abort)
    end

    deactivated_status = LeaseAgreement.statuses[:deactivate]
    active_associations = lease_agreement_units.joins(:lease_agreement)
                                               .where.not(lease_agreements: { status: deactivated_status })

    if active_associations.exists?
      errors.add(:base,
                 "Unit cannot be deleted because it is associated with an active lease agreement.")
      throw(:abort)
    else
      lease_agreement_units.destroy_all
    end
  end

  def update_property_units_count
    property.update_units_count
  end
end
