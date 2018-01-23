class Users::PasswordsController < Devise::PasswordsController

  prepend_before_filter :require_no_authentication
  # Render the #edit only if coming from a reset password email link
  append_before_filter :assert_reset_token_passed, only: :edit

  layout 'home'

  def new
    super

    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    if successfully_sent?(resource)
      respond_to do |format|
        format.html { redirect_to new_user_password_path, :notice => t(".sent") }
        format.js { render :create }
      end
    else
      respond_to do |format|
        format.html { redirect_to new_user_password_path, :notice => t(".error_sent") }
        format.js { render :create_ko }
      end
    end
  end

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
