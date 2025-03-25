# frozen_string_literal: true

class Tenant < ApplicationRecord
  include PublicActivity::Model
  tracked owner: lambda { |controller, _model|
    controller.try(:current_admin_user) || controller.try(:current_user) if controller.present?
  }

  belongs_to :unit, optional: true
  has_many :lease_agreements, dependent: :destroy
  has_many :rents, through: :lease_agreements

  accepts_nested_attributes_for :lease_agreements

  validates :name, :phone, :cnic, presence: true
  validates :phone, format: { with: /\A\d{11}\z/, message: "must be exactly 11 digits" }
  validates :cnic,
            format: { with: /\A\d{5}-\d{7}-\d\z/, message: "must be in the format XXXXX-XXXXXXX-X" }
  validates :balance, :advance_credit, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :set_default_balance, if: :new_record?

  def self.ransackable_attributes(_auth_object = nil)
    %w[active advance_credit balance cnic created_at email id name phone updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[activities lease_agreements rents unit]
  end

  def cnic=(value)
    digits = value.to_s.gsub(/\D/, "")
    if digits.length == 13
      super("#{digits[0, 5]}-#{digits[5, 7]}-#{digits[12]}")
    else
      super(value)
    end
  end

  def add_rent_payment(amount)
    update(balance: balance - amount)
  end

  def add_advance_payment(amount)
    update(advance_credit: advance_credit + amount)
  end

  def deduct_advance(amount)
    update(advance_credit: advance_credit - amount)
  end

  def refund_payment(amount)
    update(balance: balance + amount)
  end

  def activate
    update(active: true)
  end

  def deactivate
    update!(active: false)
  end

  private

  def set_default_balance
    self.balance ||= 0.0
    self.advance_credit ||= 0.0
  end
end
