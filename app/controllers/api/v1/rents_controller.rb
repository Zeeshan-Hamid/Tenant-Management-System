# frozen_string_literal: true

module Api
  module V1
    class RentsController < BaseController
      before_action :set_lease_agreement, only: [:pay]
      before_action :validate_lease_agreement, only: [:pay]
      before_action :validate_payment_method, only: [:pay]
      before_action :validate_months_param, only: [:pay]

      def pay
        payment_result = process_payment_request

        payment_result[:success] ?
          render(json: payment_result, status: :ok) :
          render(json: { error: payment_result[:message] }, status: :unprocessable_entity)
      end

      private

      def process_payment_request
        service = create_payment_service
        service.process_payment

        build_payment_response(service)
      end
      
      def create_payment_service
        RentPaymentService.new(
          @lease_agreement,
          params[:total_amount_paid],
          params[:months],
          params[:payment_date],
          params[:receipt_image],
          params[:payment_method]
        )
      end
      
      def build_payment_response(service)
        {
          success: service.success,
          message: build_payment_message(service),
          paid_months: service.paid_months || [],
          pending_months: service.pending_months || [],
          pending_rent: service.new_pending.to_i,
          excess_amount_added_to_balance: service.excess_amount.to_i,
          updated_rents: service.updated_rents
        }
      end

      def build_payment_message(service)
        return service.error_message unless service.success

        paid_months = service.paid_months || []
        pending_months = service.pending_months || []

        message = []

        message << "Rent paid for #{paid_months.join(', ')}." if paid_months.any?
        message << "Partial payment recorded for #{pending_months.join(', ')}." if pending_months.any?
        message << "#{service.excess_amount.to_i} added to tenant balance." if service.excess_amount.positive?

        message.join(" ")
      end

      def set_lease_agreement
        @lease_agreement = LeaseAgreement.find_by(id: params[:lease_id])
      end

      def validate_lease_agreement
        unless @lease_agreement
          render json: { error: I18n.t("errors.lease_not_found") }, status: :not_found
        end
      end

      def validate_payment_method
        unless params[:payment_method].present? && %w[cash online].include?(params[:payment_method])
          render json: { error: "Payment method must be either 'cash' or 'online'" }, status: :unprocessable_entity
        end
      end

      def validate_months_param
        unless valid_months_array? && valid_month_entries? && valid_payment_total?
          return
        end
      end
      
      def valid_months_array?
        unless params[:months].is_a?(Array)
          render_error("The months parameter is invalid. It should be an array.")
          return false
        end
        true
      end
      
      def valid_month_entries?
        invalid_entries = params[:months].reject { |m| valid_month_object?(m) }
        
        if invalid_entries.any?
          render_error("Invalid month format in request. Each month object must have 'month' in format 'Mar-2025' and 'payment_amount' must be a positive number.")
          return false
        end
        true
      end
      
      def valid_payment_total?
        total_specified = calculate_total_payments
        
        if total_specified > params[:total_amount_paid].to_i
          render_error("The sum of payment amount (#{total_specified}) exceeds total_amount_paid (#{params[:total_amount_paid]}).")
          return false
        end
        true
      end
      
      def render_error(message)
        render json: { error: message }, status: :bad_request
      end
      
      def calculate_total_payments
        params[:months].sum do |month_obj|
          month_hash = normalize_to_hash(month_obj)
          payment_key = find_key(month_hash, [ "payment_amount", "paymentAmount" ])
          month_hash[payment_key].to_i
        end
      end
      
      def normalize_to_hash(obj)
        obj.is_a?(ActionController::Parameters) ? obj.to_unsafe_h : obj
      end
      
      def valid_month_object?(month_obj)
        month_hash = normalize_to_hash(month_obj)
        
        return false unless month_hash.is_a?(Hash)
        
        keys_valid = check_required_keys(month_hash)
        return false unless keys_valid
        
        month_str = month_hash[find_key(month_hash, [ "month", "Month" ])].to_s
        valid_month_format?(month_str)
      end
      
      def check_required_keys(month_hash)
        month_key = find_key(month_hash, [ "month", "Month" ])
        payment_key = find_key(month_hash, [ "payment_amount", "paymentAmount" ])
        
        return false unless month_key.present? && payment_key.present?
        return false unless month_hash[payment_key].to_i > 0
        
        true
      end
      
      def valid_month_format?(month_str)
        month_pattern = /\A[A-Z][a-z]{2}-\d{4}\z/
        month_pattern.match?(month_str)
      end
      
      def find_key(hash, possible_keys)
        possible_keys.find { |k| hash.key?(k) }
      end
    end
  end
end
