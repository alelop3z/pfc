class Users::SessionsController < Devise::SessionsController
  
  layout 'home'

  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)

    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  def create
    respond_to do |format|
      format.html { super }
      format.js { 
        warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
        render :js => "window.location.href = '#{wall_user_path(current_user)}'"
        }
    end
  end

  def destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)

    respond_to do |format|
      format.html { 
        super
      }
    end
  end

  def failure
    respond_to do |format|
      format.js { render action: :create}
    end
  end

end
