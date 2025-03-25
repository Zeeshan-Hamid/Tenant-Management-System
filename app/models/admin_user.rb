# frozen_string_literal: true

class AdminUser < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  include PublicActivity::Model

  tracked owner: lambda { |controller, _model|
    controller.try(:current_admin_user) if controller.present?
  }

  attribute :access_level, :integer, default: 3

  enum access_level: { administrator: 1, property_manager: 2, unit_manager: 3 }

  before_destroy :prevent_administrator_destruction

  def self.ransackable_attributes(_auth_object = nil)
    %w[access_level created_at email encrypted_password id id_value updated_at]
  end

  def prevent_administrator_destruction
    return unless administrator?

    errors.add(:base, "Super Admin cannot be deleted")
    throw(:abort)
  end
end
