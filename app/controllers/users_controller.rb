class UsersController < ApplicationController

  before_action :set_user, :only => [:add_answer_to_comments, :add_comment, :add_follow, :change_password, :create_destination, :del_destination, :del_follow, :destroy, :edit, :events, :favorites, :follows, :followers, :inbox, :routes, :show, :update, :wall]
  before_action :set_current_user, :only => [:destroy_user, :edit_user, :reload_menu, :update_user]

  # Añadir un comentario en mi muro de usuario
  def add_comment
    @comment = current_user.comments.new(:text => params[:message])
    
    if params[:id] != current_user.id_to_s
      @comment.object_id = params[:id]
      @comment.object_type = @comment.class
    end

    if @comment.save
      respond_to do |format|
        format.html { redirect_to wall_user_path(params[:id]) }
        format.json { render :json => {:comment => @comment.as_json(json: 'wall')}}
      end
    else
      respond_to do |format|
        format.html { render :action => :wall }
        format.json { render json: {errors: @comment.errors.map{|attr, msg| msg}}, status: :unprocessable_entity }
      end
    end
  end

  # Añadir un favorito al usuario
  def add_favorite
    _type = params[:type].capitalize

    if current_user.favorites.where(:object_type => _type, :object_id => params[:id]).size > 0 
      current_user.del_favorite(params[:id], _type)
    else
      current_user.add_favorite(params[:id], _type)
    end

    respond_to do |format|
      format.html { redirect_to wall_user_path(@user)}
      format.json { render :json => { user: current_user.as_json(:json => 'wall') }}
    end
  end

  # Añadir un usuario a mi listado de siguiendo
  def add_follow
    current_user.add_follow(@user)

    respond_to do |format|
      format.html { redirect_to wall_user_path(@user)}
      format.json { render :json => { user: @user.as_json(:json => 'wall') }}
    end
  end

  # Añadir un mensaje a una conversación
  def add_message
    @conversation = Conversation.find(params[:id])

    if @conversation.add_msg({:text => params[:message]}, current_user.id_to_s)
      respond_to do |format|
        format.html { redirect_to conversation_user_path(params[:id]) }
        format.json { render :json => { :conversation => @conversation.as_json(:json => "wall") }}
      end
    else
      respond_to do |format|
        format.html { redirect_to conversation_user_path(params[:id]) }
        format.json { render :json => {:conversation => @conversation.as_json(:json => "wall"), :status => :unprocessable_entity}}
      end
    end
  end
  
  # Listado de todos los usuarios que estoy siguiendo y que no soy yo
  def all
    @users = User.only(:id, :name, :about_me, :avatar_file_name, :avatar_updated_at).not_in(:id => current_user.follow_ids).not_in(:id => [current_user])

    respond_to do |format|
      format.html
      format.json { render :json => { :users => @users.as_json(:json => 'wall') }}
    end
  end

  # Responder a un comentario ya escrito (da igual el tipo pero siempre será de tipo comentario)
  # por lo que obviamos dicho campo
  def answer_comment
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.html { redirect_to comment_path(@comment)}
      format.json { render :json => { :comment => @comment }}
    end
  end

  # Pantalla de cambio de password
  def change_password
    if session[:user_id].blank?
      if @user and !@user.token.blank? and @user.token == params[:token]
        # Guardo el usuario en sesion si es que no estaba ya almacenado
        session[:user_id] = @user.id if session[:user_id].blank?

        # Elimino el token actual ya que no tiene sentido una vez entramos en esta pantalla
        @user.token = nil
        @user.save(:run_callbacks => false)

        # Guardo el id del usuario en sesion y redirijo a su muro con la contraseña modificada
        flash.now.notice = t("user.password_has_changed")
        session[:user_id] = @user.id
        redirect_to "/"
      else
        flash.now.error = t("user.invalid")
        redirect_to :action => :remember_password
      end
    end
  end

  # Cerrar un comentario tras haberlo abierto
  def close_comment
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.html { redirect_to comment_path(@comment)}
      format.json { render :json => { :comment => @comment }}
    end
  end

  # Conversación concreta con un usuario
  def conversation
    @user = User.find(params[:id])
    # Obtengo la conversación con el usuario o creamos una nueva
    @conversation = current_user.conversation(@user.id_to_s)

    respond_to do |format|
      format.html { }
      format.json { render :json => { :conversation => @conversation.as_json(:json => "wall"), :user => @user.as_json(:json => 'wall') }}
    end
  end


  # Eliminar a un usuario de mi lista de Siguiendo
  def del_follow
    current_user.del_follow(@user)

    respond_to do |format|
      format.html { redirect_to wall_user_path(@user) }
      format.json { render :json => { user: @user.as_json(:json => 'wall') }}
    end
  end

  # Eliminación de un usuario
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  # Edición de perfil
  def edit_user
    @current_user = @user

    respond_to do |format|
      format.html
      format.json { render :json => {:user => @user.as_json(json: "all")}}
    end
  end

  def events
    @events = Event.where(:user_id => @user._id.to_s)
    @events = @events.where(:published => true) if current_user.id_to_s != params[:id]
    @events = @events.desc(:init_date)

    respond_to do |format|
      format.html
      format.json { render :json => { :events => @events.as_json(:json => "wall"), :user => @user.as_json(:json => 'wall') }}
    end
  end

  # Mis favoritos
  def favorites
    @favorites = @user.objects_favorites((params[:type] || "route").capitalize)

    respond_to do |format|
      format.html
      format.json { render :json => { :objects => @favorites.as_json(:json => "wall"), :user => @user.as_json(:json => 'wall') }}
    end
  end

  # A quien sigue el usuario
  def follows
    @follows = @user.follows

    respond_to do |format|
      format.html
      format.json { render :json => { :follows => @follows.map{|x| x.as_json(:json => 'friendship')}, :user => @user.as_json(:json => 'wall') }}
    end
  end

  # A quien sigue el usuario
  def followers
    @followers = @user.followers

    respond_to do |format|
      format.html
      format.json { render :json => { :followers => @followers.map{|x| x.as_json(:json => 'friendship')}, :user => @user.as_json(:json => 'wall') }}
    end
  end

  # Inbox de mensajería interna (no hay diferenciación entre enviados y no enviados)
  def inbox
    @conversations = @user.conversations

    respond_to do |format|
      format.html
      format.json { render :json => { :conversations => @conversations.as_json(:json => "wall"), :user => current_user.as_json(json: 'wall') }}
    end
  end

  def index
    @users = User.all

    respond_to do |format|
      format.html
      format.json { render :json => { :users => @users }}
    end
  end

  # Ver el perfil del usuario
  # Pantalla de edición del mismo
  def profile
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # Actualización de los datos de usuario
  def update_user
    @user = User.find(params[:id])

    respond_to do |format|
      if needs_password?(params[:user])
        if @user.update_attributes(params[:user])
          format.html { redirect_to wall_user_path(@user), :notice => t("users.updated") }
          format.json { render :json => @user.as_json(:methods => [:id_to_s, :photo]) }
        else
          format.html { render :action => :edit }
          format.json { render :json => @user.errors, :status => :unprocessable_entity }
        end
      else
        if @user.update_without_password(params[:user])
          format.html { redirect_to wall_user_path(@user), :notice => t("users.updated") }
          format.json { render :json => @user.as_json(:methods => [:id_to_s, :photo]) }
        else
          format.html { render :action => :edit }
          format.json { render :json => @user.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # Recarga del menú superior
  def reload_menu
    respond_to do |format|
      format.json { render :json => {:user => @user.as_json(:json => "reload_menu") }}
    end
  end

  # Recordatorio de contraseña
  def remember_password
    if request.post?
      @user = User.where(:email => params[:email]).first

      # Si hay usuario es que existe un usuario al que cambiarle la contraseña
      if @user
        # Genero un token y lo guardamos en el usuario
        # Después se enviará al usuario para que haya un mínimo control de quien puede recordar contraseña y quien no
        @user.token = @user.make_token_code
        @user.save(:run_callbacks => false)

        # Se envia el correo al usuario para que pueda cambiar la contraseña
        @user.mail_remember_password

        # Pongo el flash notice de que se ha enviado el correo
        flash.now.notice = t("users.mail_remember_password_sent")
        # No existe usuario, ya sea por no llenar la información o porque no existe ninguno en base de datos
      else
        if params[:email].blank?
          flash.now.error = t("users.fill_fields_remember_password")
        else
          flash.now.error = t("users.invalid")
        end
      end
    end
  end

  # Listado con las rutas creadas por el usuario en cuestión
  def routes
    @routes = Route.where(:user_id => @user._id.to_s)
    @routes = @routes.where(:ready => true) if current_user.id_to_s != params[:id]
    @routes = @routes.desc(:created_at)

    respond_to do |format|
      format.html
      format.json { render :json => {:routes => @routes.as_json(:json => 'wall'), :user => @user.as_json(:json => 'wall') }}
    end
  end

  # Búsqueda de usuarios por nombre
  def search
    @users = User.search(params)

    respond_to do |format|
      format.html
      format.json { render :json => {:users => @users.map{|x| x.as_json(:json => 'search')} }}
    end
  end

  # Detalle de un usuario
  def show
    respond_to do |format|
      format.html
      format.json { render :json => {:user => @user.as_json(:json => 'wall') }}
    end
  end

  # Obtengo mi perfil de usuario
  def user
    @user = current_user

    respond_to do |format|
      format.json { render :json => {:user => @user.as_json(:json => 'wall') }}
    end
  end

  # Muro de usuario con sus comentarios o los de los participantes que sigue
  def wall
    current_user.id_to_s == @user.id_to_s ? @comments = Comment.user_wall(@user, params[:timestamp]) : @comments = Comment.user_tweets(@user, params[:timestamp])

    respond_to do |format|
      format.html
      format.json { render :json => { :comments => @comments.as_json(:json => 'wall'), :user => @user.as_json(:json => 'wall') } }
    end
  end

  # Quitar amistad con un usuario
  def unfriendship
    if params[:id]
      current_user.follow_ids.delete(params[:id])
      @user = User.find(params[:id]).del_follower(current_user)
      @user.save
      current_user.save
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  protected

    # Redirijo a mi muro en caso de estar logueado
    def redirect_to_wall
      redirect_to wall_user_path(current_user) if current_user
    end

    # Necesito actualizar contraseña ?
    def needs_password?(_params)
      !_params[:password].blank?
    end

    # Sólo current_user
    def set_current_user
      current_user.blank? ? @user = nil : @user = current_user
    end

    # Setter de usuario, a partir del params[:id] que llega
    # generamos una variable @user usada en las acciones elegidas
    def set_user
    	params[:id].blank? ? (@user = current_user) : (@user = User.find(params[:id]))
    end

end