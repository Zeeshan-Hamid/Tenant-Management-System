# frozen_string_literal: true

class RentGeneratorJob < ApplicationJob
  queue_as :default

  def perform
    return unless Date.today.day == 1

    Tenant.active.find_each do |tenant|
      next if Rent.exists?(tenant: tenant, payment_date: Date.today.beginning_of_month)

      Rent.create!(
        tenant: tenant,
        unit: tenant.unit, # Assuming tenant has a unit association
        amount: tenant.monthly_rent,
        payment_date: Date.today.beginning_of_month,
        status: "pending"
      )
    rescue StandardError => e
      Rails.logger.error "Failed to create rent record for tenant #{tenant.id}: #{e.message}"
    end
  end
end
