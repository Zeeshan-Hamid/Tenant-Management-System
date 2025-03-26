# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_request!, only: [ :update_name ]

      def update_name
        if @current_user.update!(name: params[:name], profile_completed: true)
          render json: { message: "Name updated successfully", user: @current_user.as_json(only: %i[id name phone_number profile_completed]) },
status: :ok
        else
          render json: { error: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
