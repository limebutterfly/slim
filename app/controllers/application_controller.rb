class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :basic
  private
  def basic
    authenticate_or_request_with_http_basic do |user, pass|
      user == 'slim' && pass == 'fat'
    end
  end
end
