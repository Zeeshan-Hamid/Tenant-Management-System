class RentGeneratorJob
  include Sidekiq::Job

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    lease_agreement = tenant.lease_agreement

    return unless lease_agreement.present?

    rent_amount = lease_agreement.rent_amount

    Rent.create!(
      tenant: tenant,
      unit: tenant.units.first, # Assuming one unit per tenant
      amount: rent_amount,
      payment_date: Date.today,
      status: 'pending'
    )
  end
end
