# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include PublicActivity::StoreController
  allow_browser versions: :modern

  before_action :authenticate_admin_user!, unless: :devise_controller?
end
