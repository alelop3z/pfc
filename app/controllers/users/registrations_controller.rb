class Users::RegistrationsController < Devise::RegistrationsController
# before_filter :configure_sign_up_params, only: [:create]
# before_filter :configure_account_update_params, only: [:update]

  layout 'home'

  # GET /resource/sign_up
  def new
    build_resource
  end

  # POST /resource
  def create
    build_resource(sign_up_params)

    if resource.save
      resource.update_attribute(:encrypted_password, Devise.bcrypt(resource.class, sign_up_params[:password]))
      resource.mail_welcome
      sign_up(resource_name, resource)
      
      respond_to do |format|
        format.html { redirect_to wall_user_path(current_user) }
        format.js { render :js => "window.location.href = '#{tutorial_user_path(current_user)}'" }
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
        format.js
      end
    end
  end


  protected

    def sign_up_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

end
