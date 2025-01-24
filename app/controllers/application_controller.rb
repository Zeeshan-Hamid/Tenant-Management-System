class ApplicationController < ActionController::Base
  before_action do
    ActiveStorage::Current.host = request.base_url
  end
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
