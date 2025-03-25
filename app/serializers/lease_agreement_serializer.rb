# frozen_string_literal: true

class LeaseAgreementSerializer < ActiveModel::Serializer
  include PropertiesConcern

  attributes :lease_id, :property_id, :unit_names, :unit_floors,
             :tenant_name, :tenant_number, :tenant_balance, :rent_amount, :rent_status,
             :pending_amount, :due_date, :payment_history_ledger, :rent_generation_history

  def lease_id
    object.id
  end

  def property_id
    object.property_id
  end

  def unit_names
    object.units.pluck(:unit_number)
  end

  def unit_floors
    object.units.map(&:floor)
  end

  def tenant_name
    tenant.name
  end

  def tenant_number
    tenant.phone
  end

  def tenant_balance
    tenant.balance
  end

  def rent_record
    @rent_record ||= fetch_relevant_rent
  end

  def rent_amount
    rent_record ? (rent_record.status == "paid" ? 0 : rent_record.amount.to_i) : object.rent_amount.to_i
  end

  def rent_status
    rent_record ? rent_record.status : "pending"
  end

  def due_date
    if rent_record && rent_record.status == "pending"
      rent_record.due_date
    else
      nil
    end
  end

  def pending_amount
    object.pending_rent
  end

  def rent_generation_history
    rents = filtered_rents_by_date(ordered_rents_by_payment_date)

    monthly_entries = generate_monthly_entries(rents)

    monthly_entries.map do |entry|
      original_amount = entry[:rent_amount].to_i
      amount_paid = entry[:amount_paid].to_i

      pending_amount = entry[:status] == "paid" ? 0 : (original_amount - amount_paid)

      {
        month: entry[:date].strftime("%b-%Y"),
        rent_amount: original_amount,
        status: entry[:status] == "paid" ? "paid" : "pending",
        paid_date: entry[:status] == "paid" ? entry[:payment_date]&.strftime("%Y-%m-%d") : nil,
        amount_paid: amount_paid,
        pending_amount: pending_amount
      }
    end
  end

  def payment_history_ledger
    ledger_entries = []
    rents = filtered_rents_by_date(object.rents.order(:payment_date))
    carry = 0.0

    rents.each do |rent|
      entry, carry = ledger_entry_for_rent(rent, carry, tenant)
      ledger_entries << entry
    end

    if ledger_entries.empty? || should_add_current_month_entry?(ledger_entries)
      ledger_entries << current_month_entry(carry, tenant)
    end

    ledger_entries
  end

  private

  def tenant
    @tenant ||= object.tenant
  end

  def month_param
    @month_param ||= @instance_options[:month]
  end

  def ordered_rents_by_payment_date
    @ordered_rents_by_payment_date ||= object.rents.order(payment_date: :asc)
  end

  def fetch_relevant_rent
    if month_param.present?
      find_rent_for_month(object, month_param)
    else
      object.rents.order(due_date: :desc).first
    end
  end

  def filtered_rents_by_date(rents)
    return rents unless month_param.present?

    date_range = month_date_range(month_param)
    return rents unless date_range

    # Filter rents up to and including the specified month
    rents.select { |rent| rent.payment_date <= date_range[:end_date] }
  end

  def should_add_current_month_entry?(ledger_entries)
    return true if ledger_entries.empty?

    if month_param.present?
      date_range = month_date_range(month_param)
      return false unless date_range

      last_entry_date = ledger_entries.last[:date]
      target_month_start = date_range[:start_date]

      last_entry_date < target_month_start
    else
      ledger_entries.last[:date] < Date.current.beginning_of_month
    end
  end

  def generate_monthly_entries(rents)
    return [] if rents.empty?

    start_date = rents.first.payment_date.beginning_of_month
    end_date = determine_end_date

    monthly_entries = initialize_monthly_entries(start_date, end_date)

    update_entries_with_rent_data(monthly_entries, rents)

    monthly_entries.values.sort_by { |entry| entry[:date] }
  end

  def determine_end_date
    if month_param.present?
      date_range = month_date_range(month_param)
      date_range ? date_range[:end_date].beginning_of_month : Date.current.beginning_of_month
    else
      Date.current.beginning_of_month
    end
  end

  def initialize_monthly_entries(start_date, end_date)
    entries = {}
    current_date = start_date

    while current_date <= end_date
      entries[current_date] = create_default_entry(current_date)
      current_date = current_date.next_month
    end

    entries
  end

  def create_default_entry(date)
    {
      date: date,
      rent_amount: object.rent_amount,
      status: "pending",
      payment_date: nil,
      amount_paid: 0
    }
  end

  def update_entries_with_rent_data(entries, rents)
    rents.each do |rent|
      month_key = rent.payment_date.beginning_of_month

      if entries.key?(month_key)
        entries[month_key] = create_entry_from_rent(month_key, rent)
      end
    end
  end

  def create_entry_from_rent(month_key, rent)
    {
      date: month_key,
      rent_amount: rent.amount,
      status: rent.status,
      payment_date: rent.status == "paid" ? rent.payment_date : nil,
      amount_paid: rent.amount_paid || 0
    }
  end

  def ledger_entry_for_rent(rent, carry, tenant)
    standard_rent = rent.amount.to_i
    adjusted_total = compute_adjusted_total(standard_rent, carry)
    amount_paid = compute_amount_paid(rent)
    amount_pending, new_carry = compute_amounts(adjusted_total, amount_paid)

    entry = {
      date: rent.payment_date,
      standard_rent: standard_rent,
      adjusted_total: adjusted_total,
      amount_paid: amount_paid,
      amount_pending: amount_pending,
      tenant_balance: tenant.balance.to_i,
      status: rent.status
    }
    [ entry, new_carry ]
  end

  def compute_adjusted_total(standard_rent, carry)
    adjusted = standard_rent - carry
    adjusted.negative? ? 0.0 : adjusted
  end

  def compute_amount_paid(rent)
    rent.amount_paid.to_i
  end

  def compute_amounts(adjusted_total, amount_paid)
    if amount_paid < adjusted_total
      amount_pending = adjusted_total - amount_paid
      new_carry = 0.0
    else
      amount_pending = 0.0
      new_carry = amount_paid - adjusted_total
    end
    [ amount_pending, new_carry ]
  end

  def current_month_entry(carry, tenant)
    standard_rent = object.rent_amount.to_i
    adjusted_total = compute_adjusted_total(standard_rent, carry)
    target_date = get_target_date

    {
      date: target_date,
      standard_rent: standard_rent,
      adjusted_total: adjusted_total,
      amount_paid: 0.0,
      amount_pending: adjusted_total,
      tenant_balance: tenant.balance.to_i,
      status: "pending"
    }
  end

  def get_target_date
    if month_param.present?
      date_range = month_date_range(month_param)
      date_range ? date_range[:start_date] : Date.current.beginning_of_month
    else
      Date.current.beginning_of_month
    end
  end
end
