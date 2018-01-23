class EventsController < ApplicationController

  before_action :set_event, :only => [:add_comment, :destroy, :destroy_event, :download, :edit, :remove, :show, :update]

  # Añadir un comentario en mi muro de usuario
  def add_comment
    if current_user
      @comment = current_user.comments.new(:object_id => @event.id_to_s, :object_type => @event.class, :text => params[:comment], :type => Comment::Event.last)

      if @comment.save
        @comments = Comment.get_object_comments(@event, params[:timestamp])

        respond_to do |format|
          format.html { redirect_to event_path(params[:id]) }
          format.json { render :json => {:comment => @comments.as_json(json: "wall")}}
        end
      else
        respond_to do |format|
          format.html { render :action => :show }
          format.json { render :json => {:comment => @comment.errors, :status => :unprocessable_entity}}
        end
      end
    else
      respond_to do |format|
        format.html { render :action => :show }
        format.json { render :json => {:status => :unprocessable_entity}}
      end
    end
  end

  # Creación de un evento a partir de los parámetros enviados
  def create
    @event = Event.new(params[:event])
    @event.user = current_user

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: t("events.created") }
        format.json { render json: {event: @event.as_json(json: 'show')} }
      else
        format.html { render action: "new" }
        format.json { render json: {errors: @event.errors.map{|attr, msg| msg}},  status: :unprocessable_entity }
      end
    end
  end

  # Borrar un evento
  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url }
      format.json { head :no_content }
    end
  end

  # Borrar un evento
  def destroy_event
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url }
      format.json { head :no_content }
    end
  end

  # Edición de un evento
  def edit
    @markers = Gmaps4rails.build_markers(@event) do |point, marker|
      marker.lat point.lat
      marker.lng point.lng
    end

    respond_to do |format|
      format.html {}
      format.json { render :json => {:event => @event.as_json(json: 'edit'), :markers => @markers}}
    end
  end

  # Listado de eventos
  def index
    @events = Event.search(params)
    @markers = Gmaps4rails.build_markers(@events) do |point, marker|
      icon = set_icon(point)

      marker.lat point.lat
      marker.lng point.lng
      marker.picture({
        "url" => icon,
        "width" => 32,
        "height" => 37 })
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: {events: @events.as_json(:json => "wall"), markers: @markers }}
    end
  end

  # Nuevo evento
  def new
    @event = Event.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: {event: @event.as_json(:json => "edit"), marker: @event.marker} }
    end
  end

  # Detalle de un evento
  def show
    # Obtengo los comentarios del objeto seleccionado
    @comments = Comment.get_object_comments(@event, params[:timestamp])
    @markers = Gmaps4rails.build_markers(@event) do |point, marker|
      icon = set_icon(point)

      marker.lat point.lat
      marker.lng point.lng
      marker.picture({
        "url" => icon,
        "width" => 32,
        "height" => 37 })
    end

    @event.update_last_visit_at

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: {comments: @comments.as_json(json: "wall"), current_user: current_user.as_json(json: "wall"), event: @event.as_json(json: "show"), markers: @markers, user: @event.user.as_json(json: "wall") }}
    end
  end

  # Actualización de un evento a partir de sus parámetros
  def update
    @event = Event.find(params[:id])

    respond_to do |format|
      if @event.update_attributes(params[:event])
        format.html { redirect_to @event, :notice => t(".updated") }
        format.json { render json: {event: @event.as_json(json: 'show') }}
      else
        format.html { render :action => "edit" }
        format.json { render json: {errors: @event.errors.map{|attr, msg| msg}}, :status => :unprocessable_entity }
      end
    end
  end


  protected

    def set_event
      @event = Event.find(params[:id])
    end

    # Setter de icono para la ruta
    def set_icon(point)
      point.ico_event_type(true)["icon"]
    end

end
