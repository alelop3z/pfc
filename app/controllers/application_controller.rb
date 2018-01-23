class ApplicationController < ActionController::Base

  protect_from_forgery
  before_filter :set_locale
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }
  
  # Authorizations
  # Admin authorization
  def authorize_admin
  	redirect_to root_path, notice: "No tiene permiso para acceder a esta sección" if current_user.blank? or !current_user.admin?
  end

  # User authorization
  def authorize_user
  	redirect_to root_path, notice: "No tiene permiso para acceder a esta sección" if current_user.blank?
  end

  protected

    def set_locale(_params = {})
      I18n.locale = (!_params[:lang].blank? ? _params[:lang] : extract_locale_from_accept_language_header)
    end

  private

    def extract_locale_from_accept_language_header
      request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    end

end
