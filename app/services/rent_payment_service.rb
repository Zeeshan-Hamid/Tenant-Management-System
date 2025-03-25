# frozen_string_literal: true

class RentPaymentService
  attr_reader :success, :new_pending, :excess_amount, :error_message, :updated_rents, :months, :paid_months, :pending_months

  def initialize(lease_agreement, total_amount_paid, months, payment_date = nil, receipt_image = nil, payment_method = nil)
    @lease_agreement = lease_agreement
    @total_amount_paid = total_amount_paid.to_i
    @months = months
    @payment_date = payment_date || Date.current
    @receipt_image = receipt_image
    @payment_method = payment_method || "cash"
    initialize_result_attributes
  end

  def initialize_result_attributes
    @success = nil
    @new_pending = 0
    @excess_amount = 0
    @error_message = nil
    @updated_rents = {}
    @paid_months = []
    @pending_months = []
  end

  def process_payment
    return @success unless @success.nil?

    begin
      unless valid_months_format?
        mark_as_failed("Invalid month format in request")
        return @success
      end

      ActiveRecord::Base.transaction do
        remaining_amount = process_monthly_payments(@total_amount_paid)
        handle_excess_amount(remaining_amount)
        update_receipt_image if @receipt_image.present?
        @success = true
      end
    rescue StandardError => e
      mark_as_failed("Payment processing failed: #{e.message}")
    end

    @success
  end

  private

  def mark_as_failed(message)
    @success = false
    @error_message = message
  end

  def process_monthly_payments(remaining_amount)
    @months.each do |month_data|
      payment_info = extract_payment_info(month_data)
      next unless payment_info

      month_str = payment_info[:month_str]
      payment_amount = payment_info[:payment_amount]

      rent = find_rent_record(month_str)
      next unless rent

      process_single_payment(rent, month_str, payment_amount)
      remaining_amount -= payment_amount
    end

    remaining_amount
  end

  def extract_payment_info(month_data)
    month_data = normalize_to_hash(month_data)

    month_key = find_key(month_data, [ "month", "Month" ])
    payment_key = find_key(month_data, [ "payment_amount", "paymentAmount" ])

    month_str = month_data[month_key]
    payment_amount = month_data[payment_key].to_i

    { month_str: month_str, payment_amount: payment_amount }
  end

  def find_rent_record(month_str)
    month_date = parse_month_to_date(month_str)
    return nil unless month_date

    rent = find_rent_for_month(month_date)

    unless rent
      @error_message = "No rent record found for #{month_str}"
      return nil
    end

    rent
  end

  def process_single_payment(rent, month_str, payment_amount)
    original_rent_amount = rent.amount.to_i
    payment_status = determine_payment_status(payment_amount, original_rent_amount)

    before_update = capture_rent_state(rent)
    update_rent_with_payment(rent, payment_status, payment_amount)
    after_update = capture_rent_state(rent)

    track_payment_status(month_str, payment_status)

    remaining_pending = calculate_remaining_pending(original_rent_amount, payment_amount)
    record_rent_update(rent, payment_status, remaining_pending, before_update, after_update)

    @new_pending += remaining_pending
  end

  def determine_payment_status(payment_amount, original_rent_amount)
    payment_amount < original_rent_amount ? "pending" : "paid"
  end

  def capture_rent_state(rent)
    {
      id: rent.id,
      status: rent.status,
      amount_paid: rent.amount_paid,
      payment_method: rent.payment_method,
      payment_date: rent.payment_date
    }
  end

  def update_rent_with_payment(rent, status, payment_amount)
    rent.status = status
    rent.payment_method = @payment_method
    rent.payment_date = @payment_date
    rent.amount_paid = payment_amount

    rent.save!
    rent.reload
  end

  def calculate_remaining_pending(original_amount, payment_amount)
    remaining = [original_amount - payment_amount, 0].max
  end

  def handle_excess_amount(remaining_amount)
    if remaining_amount > 0
      @excess_amount = remaining_amount
      add_excess_to_tenant_balance
    end
  end

  def track_payment_status(month_str, status)
    target_list = status == "paid" ? @paid_months : @pending_months
    target_list << month_str
  end

  def valid_months_format?
    return false unless @months.is_a?(Array)

    @months.all? do |month_obj|
      month_obj = normalize_to_hash(month_obj)

      next false unless month_obj.is_a?(Hash)

      month_key = find_key(month_obj, [ "month", "Month" ])
      payment_key = find_key(month_obj, [ "payment_amount", "paymentAmount" ])

      next false unless month_key.present? && payment_key.present?
      next false unless month_obj[payment_key].to_i > 0

      month_str = month_obj[month_key].to_s
      valid_month_format?(month_str)
    end
  end

  def valid_month_format?(month_str)
    month_pattern = /\A[A-Z][a-z]{2}-\d{4}\z/
    month_pattern.match?(month_str)
  end

  def normalize_to_hash(obj)
    obj.is_a?(ActionController::Parameters) ? obj.to_unsafe_h : obj
  end

  def find_key(hash, possible_keys)
    possible_keys.find { |k| hash.key?(k) }
  end

  def parse_month_to_date(month_str)
    return nil unless month_str.present?

    month_abbr, year_str = month_str.split("-")
    return nil unless month_abbr.present? && year_str.present?

    month_names = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    month_num = month_names.index(month_abbr)
    return nil unless month_num

    month_num += 1 # Convert to 1-based index
    year = year_str.to_i

    return nil unless month_num && year > 0

    create_date(year, month_num, 1)
  end

  def create_date(year, month, day)
    Date.new(year, month, day)
  rescue Date::Error
    nil
  end

  def find_rent_for_month(month_date)
    return nil unless month_date

    date_range = calculate_month_date_range(month_date)
    query_rents_in_date_range(date_range[:start], date_range[:end])
  end

  def calculate_month_date_range(date)
    {
      start: date.beginning_of_month,
      end: date.end_of_month
    }
  end

  def query_rents_in_date_range(start_date, end_date)
    @lease_agreement.rents.where(
      "payment_date >= ? AND payment_date <= ?",
      start_date,
      end_date
    ).lock(true).first
  end

  def record_rent_update(rent, status, pending_amount, before_update = nil, after_update = nil)
    month_key = rent.payment_date.strftime("%b-%Y")
    
    @updated_rents[month_key] = {
      status: status,
      pending_amount: pending_amount,
      rent_id: rent.id,
      before: before_update,
      after: after_update
    }
  end

  def update_rent(rent, status, amount_paid, original_payment_date)
    rent.update!(
      status: status,
      payment_method: @payment_method,
      amount_paid: amount_paid,
      payment_date: original_payment_date
    )

    rent.reload
  end

  def add_excess_to_tenant_balance
    tenant = @lease_agreement.tenant
    tenant.update!(balance: tenant.balance + @excess_amount)
  end

  def update_receipt_image
    tenant = @lease_agreement.tenant
    tenant.receipt_image << @receipt_image
    tenant.save
  end
end
