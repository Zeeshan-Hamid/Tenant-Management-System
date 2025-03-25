# frozen_string_literal: true

class UserLeaseAgreement < ApplicationRecord
  belongs_to :user_property
  belongs_to :lease_agreement
  validate :lease_agreement_belongs_to_property

  private

  def lease_agreement_belongs_to_property
    return unless user_property.property_id != lease_agreement.property_id

    errors.add(:lease_agreement, "does not belong to the assigned property")
  end
end
