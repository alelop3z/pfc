module ApplicationHelper

  # Funcion que devuelve si un usuario es admin o no
  def admin?
    !session[:admin].blank?
  end

  def resource_name
   :user
  end

  def resource
   @resource ||= User.new
  end

  def devise_mapping
   @devise_mapping ||= Devise.mappings[:user]
  end

  # Encabezado de la página web (title del portal)
  def seo_title(_text)
    html = ""

    unless _text.blank?
      html += "<title>#{_text}</title>"
    end

    html
  end

  # Mensajes por pantalla de correcto
  def show_flash_message(msg, type = "success")
    html = ""

    unless msg.blank?
      html += "<div class='alert alert-block alert-#{type}'>"
      html += "<button type='button' class='close' data-dismiss='alert'>X</button>"
      html += msg
      html += "</div>"
    end

    html
  end

  # Encabezado h1
  def title(_text)
    html = ""

    unless _text.blank?
      html += "<h1>#{_text}</h1>"
    end

    html.html_safe
  end

end
