# frozen_string_literal: true

class PropertySerializer < ActiveModel::Serializer
  include PropertiesConcern
  
  attributes :id, :name, :address, :units_count, :total_rent, :total_pending_rent, :paid_leases_count, :pending_leases_count

  def units_count
    user_lease_agreements.flat_map(&:units).uniq.count
  end

  def total_rent
    if month_param.present?
      calculate_month_specific_total_rent
    else
      calculate_latest_total_rent
    end
  end

  def total_pending_rent
    total_pending = 0
    
    user_lease_agreements.each do |lease|
      if month_param.present?
        rent = find_rent_for_month(lease, month_param)
        next unless rent
        next if rent.status == "paid"
        total_pending += rent.amount.to_i
      else
        total_pending += calculate_regular_pending_rent(lease)
      end
    end
    
    total_pending
  end

  def paid_leases_count
    if month_param.present?
      count_month_specific_paid_leases
    else
      count_latest_paid_leases
    end
  end

  def pending_leases_count
    if month_param.present?
      count_month_specific_pending_leases
    else
      count_latest_pending_leases
    end
  end
  
  private
  
  def user_lease_agreements
    @user_lease_agreements ||= scope.lease_agreements.where(property_id: object.id)
  end
  
  def month_param
    @month_param ||= @instance_options[:month]
  end
  
  def calculate_month_specific_total_rent
    user_lease_agreements.sum do |lease|
      rent = find_rent_for_month(lease, month_param)
      rent ? rent.amount.to_i : 0
    end
  end
  
  def calculate_latest_total_rent
    user_lease_agreements.sum do |lease|
      latest_rent = lease.rents.order(due_date: :desc).first
      latest_rent ? latest_rent.amount.to_i : 0
    end
  end
  
  def calculate_regular_pending_rent(lease)
    latest_rent = lease.rents.order(due_date: :desc).first
    
    return 0 if latest_rent && latest_rent.status == "paid"
    
    if lease.pending_rent.to_i > 0
      lease.pending_rent.to_i
    elsif latest_rent && latest_rent.status == "pending" && lease.pending_rent.to_i == 0
      latest_rent.amount.to_i
    else
      0
    end
  end
  
  def count_month_specific_paid_leases
    user_lease_agreements.count do |lease|
      rent = find_rent_for_month(lease, month_param)
      rent && rent.status == "paid"
    end
  end
  
  def count_latest_paid_leases
    user_lease_agreements.count do |lease|
      latest_rent = lease.rents.order(due_date: :desc).first
      latest_rent && latest_rent.status == "paid"
    end
  end
  
  def count_month_specific_pending_leases
    user_lease_agreements.count do |lease|
      rent = find_rent_for_month(lease, month_param)
      rent && rent.status != "paid"
    end
  end
  
  def count_latest_pending_leases
    user_lease_agreements.count do |lease|
      latest_rent = lease.rents.order(due_date: :desc).first
      latest_rent && latest_rent.status != "paid"
    end
  end
end
