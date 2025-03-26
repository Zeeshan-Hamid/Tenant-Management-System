# frozen_string_literal: true

module LeaseAgreementsConcern
    extend ActiveSupport::Concern

    private

    def set_lease_agreement
       @lease_agreement = user_lease_agreements.find_by(id: params[:id]) if params[:id].present?
    end

    def user_lease_agreements
      current_user.lease_agreements.where(property_id: @property.id).distinct
    end

    def set_user_property
      @property = current_user.properties.find_by(id: params[:property_id]) ||
                  (render(json: { error: I18n.t("api.lease_agreement.errors.property_not_found") }, status: :not_found) and return)
    end
end
