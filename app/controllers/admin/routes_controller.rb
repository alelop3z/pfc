class Admin::RoutesController < ApplicationController

	# Filtros previos a ejecutar en las acciones
	before_filter :authorize_admin
	before_filter :set_route, only: [:destroy, :edit, :update]

	# Layout de administracion
	layout 'admin'

	# Crear ruta a partir de los parámetros enviados
	def create
		@route = Route.new(params[:route])

		if @route.save
			redirect_to admin_routes_path, notice: t("admin.routes.created")
		else
			render :new
		end
	end

	# Borrado de una ruta seleccionada
	def destroy
		if @route.destroy
			respond_to do |format|
				format.html {
					redirect_to admin_routes_path, notice: t("admin.routes.destroyed")
					}
				format.js{}
			end
		else
			redirect_to admin_routes_path, error: t("admin.routes.dont_destroy")
		end
	end

	# Edición de la ruta seleccionada
	def edit
		@markers = Gmaps4rails.build_markers(@route) do |point, marker|
			marker.lat point.lat
			marker.lng point.lng
		end

		@points = Gmaps4rails.build_markers(@route) do |point, marker|
			marker.lat point.lat
			marker.lng point.lng
		end
	end

	# Listado con todas las rutas del sistema
	def index
		@routes = Route.search(params[:route])

		respond_to do |format|
			format.csv { send_data @routes.to_csv }
			format.html { @routes = @routes.page((params[:page] || 1)).per(Route::PER_PAGE) }
			format.xls
		end
	end

	# Nueva ruta desde administración
	def new
		@route = Route.new
	end

	# Actualización de la ruta seleccionada
	def update
		if @route.update_attributes(params[:route])
			redirect_to admin_routes_path, notice: t("admin.routes.updated")
		else
			render :edit
		end
	end

	protected

		# Setter de ruta a partir del parametro enviado
		def set_route
			@route = Route.find(params[:id])
		end

end