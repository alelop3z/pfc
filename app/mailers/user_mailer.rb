class UserMailer < ActionMailer::Base
  default :from => "no-reply@voyenbici.com"

  # Funcion que envia a una página donde recuperar la contraseña (metiendo una nueva)
  def remember_password(_user)
    @user = _user
    mail(:to => setup_mail(_user), :subject => t("users.mailer.remember_password"))
  end

  def welcome(_user)
    @user = _user
    mail(:to => setup_mail(_user), :subject => t("users.mailer.registration_confirmation"))
  end


  private

    def setup_mail(_user)
      !_user.name.blank? ? "#{_user.name} <#{_user.email}>" : "#{_user.email}"
    end

end
