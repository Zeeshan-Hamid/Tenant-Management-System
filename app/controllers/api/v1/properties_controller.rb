# frozen_string_literal: true

module Api
  module V1
    class PropertiesController < BaseController
      include PropertiesConcern
      
      before_action :authenticate_request!

      def index
        properties = current_user.properties
        month = params[:month]

        render json: {
          properties: ActiveModelSerializers::SerializableResource.new(
            pagination(properties), each_serializer: PropertySerializer, scope: current_user, month: month
          ),
          total_rent: calculate_total_rent(properties, month),
          total_pending_rent: calculate_total_pending_rent(properties, month)
        }, status: :ok
      end

      private

      def calculate_total_rent(properties, month = nil)
        user_lease_agreements = fetch_user_lease_agreements(properties.pluck(:id))

        user_lease_agreements.sum do |lease|
          if month.present?
            rent_for_month = find_rent_for_month(lease, month)
            rent_for_month ? rent_for_month.amount.to_f : 0
          else
            latest_rent = get_latest_rent(lease)
            latest_rent ? latest_rent.amount.to_f : 0
          end
        end
      end

      def calculate_total_pending_rent(properties, month = nil)
        total_pending = 0
        user_lease_agreements = fetch_user_lease_agreements(properties.pluck(:id))
        
        user_lease_agreements.each do |lease|
          total_pending += calculate_lease_pending_rent(lease, month)
        end
        
        total_pending
      end
      
      def fetch_user_lease_agreements(property_ids)
        current_user.lease_agreements
                   .includes(:rents)
                   .where(property_id: property_ids)
      end
      
      def calculate_lease_pending_rent(lease, month = nil)
        if month.present?
          calculate_month_specific_pending_rent(lease, month)
        else
          calculate_latest_pending_rent(lease)
        end
      end
      
      def calculate_month_specific_pending_rent(lease, month)
        rent = find_rent_for_month(lease, month)
        return 0 unless rent
        return 0 if rent.status == "paid"
        rent.amount.to_f
      end
      
      def calculate_latest_pending_rent(lease)
        latest_rent = get_latest_rent(lease)
        
        # Skip if rent is paid
        return 0 if rent_is_paid?(latest_rent)
        
        if has_pending_amount?(lease)
          lease.pending_rent.to_f
        elsif pending_with_zero_amount?(latest_rent, lease)
          latest_rent.amount.to_f
        else
          0
        end
      end
      
      def get_latest_rent(lease)
        lease.rents.max_by(&:due_date)
      end
      
      def rent_is_paid?(rent)
        rent && rent.status == "paid"
      end
      
      def has_pending_amount?(lease)
        lease.pending_rent.to_f > 0
      end
      
      def pending_with_zero_amount?(rent, lease)
        rent && rent.status == "pending" && lease.pending_rent.to_f == 0
      end
      
      def find_rent_for_month(lease, month_str)
        return nil unless month_str.match?(/\A[A-Z][a-z]{2}-\d{4}\z/)
        
        month_abbr, year = month_str.split('-')
        month_num = Date::ABBR_MONTHNAMES.index(month_abbr)
        return nil unless month_num
        
        start_date = Date.new(year.to_i, month_num, 1)
        end_date = start_date.end_of_month
        
        lease.rents.find do |rent|
          rent_date = rent.payment_date
          rent_date >= start_date && rent_date <= end_date
        end
      end
    end
  end
end
