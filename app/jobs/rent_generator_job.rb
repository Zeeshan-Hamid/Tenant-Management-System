# app/jobs/rent_generator_job.rb
class RentGeneratorJob < ApplicationJob
  queue_as :default

  def perform
    current_month = Date.today.beginning_of_month
    due_date = current_month + 10.days

    Tenant.where(active: true).find_each do |tenant|
      next unless tenant.lease_agreement.present?

      begin
        unless tenant.rents.where(month: current_month).exists?
          tenant.rents.create!(
            amount: tenant.lease_agreement.rent_amount,
            month: current_month,
            due_date: due_date,
            payment_date: due_date,
            status: 'pending',
            unit: tenant.unit
          )
        end
      rescue => e
        Rails.logger.error "Error generating rent for Tenant #{tenant.id}: #{e.message}"
      end
    end
  end
end