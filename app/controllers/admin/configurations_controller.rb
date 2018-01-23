class Admin::ConfigurationsController < ApplicationController

	before_filter :authorize_admin
	before_filter :set_config, only: [:destroy, :edit, :update]

	# Uso de layout administrador para las acciones aquí incluidas
	layout 'admin'

	def index
		@configs = Config.page((params[:page] || 1)).per(Config::PER_PAGE)
	end

	# Creación de un nuevo valor de configuración
	def create
		@config = Config.new(params[:config])

		if @config.save
			redirect_to admin_configurations_path, notice: t("admin.configurations.created")
		else
			render :action => :new
		end
	end

	# Nuevo objeto configuración
	def new
		@config = Config.new
	end

	# Edición de un objeto configuracion que ya existia
	def edit
	end

	# Actualización de los valores de configuración
	def update
		if @config.update_attributes(params[:config])
			redirect_to admin_configurations_path, notice: t("admin.configurations.updated")
		else
			render :action => :edit
		end
	end

	# Borrado de una configuración
	def destroy
		if @config.destroy
			flash[:notice] = t("admin.configurations.destroyed")
		else
			flash[:error] = t("admin.configurations.not_destroyed")
		end

		redirect_to admin_configurations_path
	end


	protected

		def set_config
			@config = Config.find(params[:id])
		end

end