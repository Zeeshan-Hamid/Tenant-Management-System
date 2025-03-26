# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include PublicActivity::StoreController
      before_action :authenticate_request!

      private

      def authenticate_request!
        header = request.headers["Authorization"]
        token = header.split(" ").last if header

        begin
          decoded = JsonWebToken.decode(token)
          @current_user = User.find_by(id: decoded[:user_id]) if decoded
          render json: { errors: "Not Authorized" }, status: :unauthorized unless @current_user
        rescue JWT::DecodeError
          render json: { errors: "Invalid Token" }, status: :unauthorized
        rescue JWT::ExpiredSignature
          render json: { errors: "Token has expired" }, status: :unauthorized
        rescue JWT::VerificationError
          render json: { errors: "Token verification failed" }, status: :unauthorized
        end
      end

      def pagination(list)
        list.page(params[:page]).per(params[:per_page_count])
      end
    end
  end
end
