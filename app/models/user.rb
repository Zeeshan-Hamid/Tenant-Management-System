# frozen_string_literal: true

class User < ApplicationRecord
  devise :registerable, :recoverable, :rememberable,
         authentication_keys: [ :phone_number ]

  include PublicActivity::Model
  tracked owner: lambda { |controller, _model|
    controller.try(:current_admin_user) if controller.present?
  }

  has_many :user_properties, dependent: :destroy
  has_many :properties, through: :user_properties
  has_many :user_lease_agreements, through: :user_properties
  has_many :lease_agreements, through: :user_lease_agreements

  accepts_nested_attributes_for :user_properties, allow_destroy: true,
                                                  reject_if: proc { |attributes|
                                                    lease_ids = attributes["lease_agreement_ids"] || []
                                                    lease_ids.reject(&:blank?).empty?
                                                  }

  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name phone_number updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[properties user_properties]
  end
end
