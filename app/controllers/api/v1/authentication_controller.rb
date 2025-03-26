# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ActionController::API
      include AuthConcerns
      before_action :validate_phone_number, only: [ :login, :verify_otp ]
      before_action :validate_otp, only: :verify_otp

      def login
        fetch_user ? render(json: { message: "OTP sent to #{@user.phone_number}" }, status: :ok) : nil
      end

      def verify_otp
        return unless fetch_user

        params[:otp] == "1234" ? render(json: @user, serializer: AuthSerializer,
status: :ok) : render(json: { error: "Invalid OTP" }, status: :unprocessable_entity)
      end
    end
  end
end
