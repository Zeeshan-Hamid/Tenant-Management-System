# frozen_string_literal: true

class RentGeneratorWorker
  include Sidekiq::Worker

  def perform
    lease_count = LeaseAgreement.count
    
    LeaseAgreement.find_each do |lease|

      # Skip deactivated lease agreements
      if lease.deactivate?
        next
      end

      payment_date = calculate_payment_date(Date.current)

      update_previous_rent_status(lease, payment_date)
      tenant = lease.tenant
      rent_amount = calculate_rent_amount(lease.rent_amount, tenant.balance)

      update_tenant_balance(tenant, lease.rent_amount, rent_amount)

      update_pending_rent(lease, payment_date)

      create_rent_record(lease, rent_amount, payment_date)
    end


  end

  private

  def calculate_payment_date(current_date)
    current_date.beginning_of_month
  end

  def update_previous_rent_status(lease, current_payment_date)
    # Get previous month's rent
    previous_month = current_payment_date.prev_month
    previous_rent = lease.rents.find_by(payment_date: previous_month.beginning_of_month)

    if previous_rent && previous_rent.status == "pending"
      previous_rent.update(status: "overdue")
    end
  end

  def calculate_rent_amount(lease_rent_amount, tenant_balance)
    if tenant_balance <= 0
      lease_rent_amount
    elsif tenant_balance >= lease_rent_amount
      0
    else
      lease_rent_amount - tenant_balance
    end
  end

  def update_tenant_balance(tenant, lease_rent_amount, new_rent_amount)
    balance_used = lease_rent_amount - new_rent_amount

    if balance_used > 0
      new_balance = tenant.balance - balance_used
      tenant.update(balance: new_balance)
    end
  end

  def update_pending_rent(lease, payment_date)
    previous_unpaid = lease.rents.where("payment_date < ?", payment_date)
                           .where(status: ["pending", "overdue"])

    if previous_unpaid.exists?
      additional_pending = previous_unpaid.sum(:amount).to_i
      new_pending = lease.pending_rent.to_i + additional_pending
      lease.update(pending_rent: new_pending)
    end
  end

  def create_rent_record(lease, rent_amount, payment_date)
    begin
      # Only create rent if amount is greater than zero
      if rent_amount > 0
        rent = Rent.create!(
          lease_agreement: lease,
          amount: rent_amount,
          payment_date: payment_date,
          status: "pending",
          due_date: payment_date + 10.days
        )
      else
        Rails.logger.info "Skipped creating rent for lease #{lease.id} as amount is 0 (covered by tenant balance)"
      end
    rescue StandardError => e
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
