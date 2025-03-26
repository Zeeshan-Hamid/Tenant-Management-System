# frozen_string_literal: true

module Api
  module V1
    class LeaseAgreementsController < BaseController
      include LeaseAgreementsConcern
      before_action :authenticate_request!
      before_action :set_property, only: [ :index ]

      def index
        lease_agreements = @property.lease_agreements.includes(:tenant, :units)
                                  .where(id: current_user.lease_agreement_ids)

        render json: pagination(lease_agreements),
               each_serializer: LeaseAgreementSerializer,
               month: params[:month],
               status: :ok
      end


      private

      def set_property
        @property = Property.find_by(id: params[:property_id])

        unless @property && current_user.property_ids.include?(@property.id)
          render json: { errors: "Property not found" }, status: :not_found
        end
      end
    end
  end
end
