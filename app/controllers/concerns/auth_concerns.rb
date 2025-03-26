# frozen_string_literal: true

module AuthConcerns
  extend ActiveSupport::Concern

  private

  def validate_phone_number
    params[:phone_number].present? or render(
      json: { error: I18n.t("api.authentication.errors.phone_number_required") },
      status: :unprocessable_entity
    ) and return
  end

  def validate_otp
    params[:otp].present? or render(json: { error: I18n.t("api.authentication.errors.otp_required") }, status: :unprocessable_entity) and return
  end

  def fetch_user
    @user = User.find_by(phone_number: params[:phone_number])
    @user ? true : (render(json: { error: I18n.t("api.authentication.errors.user_not_found") }, status: :unauthorized); false)
  end

  def update_username_status
    @user.update_column(:profile_completed, true) if @user
  end
end
