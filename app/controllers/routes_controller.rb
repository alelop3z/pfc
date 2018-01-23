class RoutesController < ApplicationController

  # Obtenemos la ruta antes de que se ejecuten las acciones indicadas
  before_action :set_route, :only => [:add_comment, :destroy, :destroy_route, :download, :edit, :remove, :show, :update]

  # Añadir un comentario en mi muro de usuario
  def add_comment
    if current_user
      @comment = current_user.comments.new(:object_id => @route.id_to_s, :object_type => @route.class, :text => params[:comment])

      if @comment.save
        @comments = Comment.get_object_comments(@route, params[:timestamp])
        respond_to do |format|
          format.html { redirect_to route_path(params[:id]) }
          format.json { render :json => {:comment => @comments.as_json({json: "wall"}) }}
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

  # Creación de una ruta a partir de los parámetros enviados
  def create
    params[:route] = parse_params_route_points(params[:route])
    @route = Route.new(params[:route])
    # Asignamos el usuario correspondiente
    @route.user_id = current_user.id

    respond_to do |format|
      if @route.save
        format.html {
          # Si generamos la ruta a partir del fichero redirigimos a la edición
          # sino eliminamos la ruta creada inicialmente y avisamos al usuario
          if @route.parse_gpx_file
            @route.next_step
            @route.set_location(:save => true)
            redirect_to edit_route_path(@route), :notice => t(".created")
          else
            redirect_to routes_path, :error => t(".error_created")
          end
          }
        format.json { 
          render json: {route: @route.as_json(json: 'edit') }
          }
      else
        format.html { render :action => :new }
        format.json { render :json => {:errors => @route.errors}, :status => :unprocessable_entity }
      end
    end
  end

  # Borrado de una ruta
  def destroy
    @route.destroy

    respond_to do |format|
      format.html { redirect_to routes_url, :notice => t(".destroyed") }
      format.json { head :no_content }
    end
  end

  # Borrado de una ruta
  def destroy_route
    @route.destroy

    respond_to do |format|
      format.html { redirect_to routes_url, :notice => t(".destroyed") }
      format.json { render :json => @route.as_json(json: 'wall') }
    end
  end

  # Descargar el track asociado a una ruta
  def download
    @route.update_last_download_at
    file = @route.gpx

    send_file(file)
  end

  # Edición de una ruta
  def edit
    respond_to do |format|
      format.html {}
      format.json { render :json => { route: @route.as_json({json: "edit"}) }}
    end
  end

  # Importar información para una ruta nueva a partir de una URL
  def import
    route = Import.new(params[:url], true)
    @route = Route.new(:description => route.description, :name => route.name, :points => route.points, :url => params[:url], :user_id => current_user.id_to_s)
  
    if params[:url].blank?
      @route = Route.new
      @route.errors.add(Route.human_attribute_name(:url), I18n.t("routes.errors.url_blank"))

      respond_to do |format|
        format.html { render :action => :new }
        format.json { render :json => { :errors => @route.errors.full_messages }, :status => :unprocessable_entity }
      end
    elsif !@route.valid?
      @route.errors.add(Route.human_attribute_name(:url), I18n.t("routes.errors.url_incorrect"))

      respond_to do |format|
        format.html { render :action => :new }
        format.json { render :json => { :errors => @route.errors.full_messages }, :status => :unprocessable_entity }
      end
    else
      if @route.save
        respond_to do |format|
          format.html { redirect_to route_path(@route), :notice => t(".created") }
          format.json { render :json => { :route => @route.as_json({json: "wall"}) }}
        end
      end
    end
  end

  # Listado de rutas a partir de los parámetros que lleguen en la url o por las llamadas
  # AJAX realizadas para cargar puntos en el mapa
  def index
    @routes = Route.search(params)
    @markers = Gmaps4rails.build_markers(@routes) do |point, marker|
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
      format.json { render :json => {:markers => @markers, :routes => @routes.map{|x| x.as_json(json: "wall")} }}
    end
  end

  # Nueva ruta
  def new
    @route = Route.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: {:route => @route.as_json }}
    end
  end

  # Eliminar una ruta
  def remove
    if current_user.id_to_s == @route.user_id_to_s and @route.destroy
      respond_to do |format|
        format.html { redirect_to routes_user_path(current_user), :notice => t(".destroyed") }
        format.json { render :json => { :user => current_user.as_json({json: "wall"}) }}
      end
    end
  end

  # Detalle de una ruta
  def show
    # Obtengo los comentarios del objeto seleccionado
    @comments = Comment.get_object_comments(@route, params[:timestamp])

    # Puntos y marcadores de la ruta
    @points = [set_init_point(@route), set_finish_point(@route)]
    @elevations = @route.get_elevations

    cont = 0
    @markers = Gmaps4rails.build_markers(@route.points) do |point, marker|
      marker.lat point["lat"]
      marker.lng point["lng"]
    end

    @route.update_last_visit_at

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => {:comments => @comments.as_json({json: "wall"}), :current_user => current_user.as_json({json: "wall"}), :elevations => @elevations, :markers => @markers, :points => @points, :route => @route.as_json({json: "show"}), :user => @route.user.as_json({json: "wall"})}}
    end
  end

  # Actualización de una ruta
  def update
    params[:route] = parse_params_route_points(params[:route])
    
    if @route.update_attributes(params[:route])
      respond_to do |format|
        format.html { redirect_to @route, notice: t(".updated") }
        format.json { render :json => { route: @route.as_json({json: "wall"}) } }
      end
    else
      respond_to do |format|
        format.html { render action: :edit }
        format.json { render :json => { route: @route.errors, status: :unprocessable_entity }}
      end
    end
  end


  private

    def parse_params_route_points(_params)
      unless _params[:points].blank?
        _clean_route_points = []

        _params[:points].map do |key, value|
          _clean_route_points << value
        end

        _params[:points] = _clean_route_points
      end

      _params
    end

    # Setter de icono para la ruta
    def set_icon(point)
      point.ico_route_type(true)["icon"]
    end

    # Setter de icono para final de ruta
    def set_icon_finish_flag
      return "/assets/gmaps/finish_flag.png"
    end

    # Setter de punto inicial
    def set_init_point(route)
      marker = {}
      marker["lat"] = route.points.first["lat"]
      marker["lng"] = route.points.first["lng"]
      marker["picture"] = {}
      marker["picture"]["url"] = set_icon(route)
      marker["picture"]["width"] = 32
      marker["picture"]["height"] = 37
      marker
    end

    # Setter de punto inicial
    def set_finish_point(route)
      marker = {}
      marker["lat"] = route.points.last["lat"]
      marker["lng"] = route.points.last["lng"]
      marker["picture"] = {}
      marker["picture"]["url"] = set_icon_finish_flag
      marker["picture"]["width"] = 32
      marker["picture"]["height"] = 32
      marker
    end


    # Setter de ruta
    def set_route
      @route = Route.find(params[:id])
    end

end
