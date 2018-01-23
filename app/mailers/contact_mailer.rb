class ContactMailer < ActionMailer::Base
  default :from => "no-reply@voyenbici.com"
  default :to => "alelop3z@gmail.com"

  # Funcion que envia a una página donde recuperar la contraseña (metiendo una nueva)
  def send_contact(_contact)
    @contact = _contact
    mail(:subject => t("contacts.mailer.send_contact"))
  end

end