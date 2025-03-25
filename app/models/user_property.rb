# frozen_string_literal: true

class UserProperty < ApplicationRecord
  belongs_to :user
  belongs_to :property

  has_many :user_lease_agreements, dependent: :destroy
  has_many :lease_agreements, through: :user_lease_agreements
  accepts_nested_attributes_for :user_lease_agreements, allow_destroy: true

  validates :user_id,
            uniqueness: { scope: :property_id,
                          message: "has already been assigned to this property" }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id property_id updated_at user_id]
  end
end
