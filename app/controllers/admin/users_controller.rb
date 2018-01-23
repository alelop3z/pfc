class Admin::UsersController < ApplicationController

	# Filtros previos a ejecutar en las acciones
	before_filter :authorize_admin
	before_filter :set_user, only: [:destroy, :edit, :update]

	# Layout de administracion
	layout 'admin'

	# Eliminar un usuario seleccionado
	def destroy
		if @user.destroy
			respond_to do |format|
				format.html{
					redirect_to admin_users_path, notice: t("admin.users.destroyed")
					}
				format.js {}
			end
		else	
			redirect_to admin_users_path, error: t("admin.users.dont_destroy")
		end
	end

	# Edición de un usuario seleccionado
	def edit
	end

	# Listado de todos los usuarios almacenados
	def index
		@users = User.search(params[:user]).asc(:name, :surname)

		respond_to do |format|
			format.csv { send_data @users.to_csv }
			format.html { @users = @users.page((params[:page] || 1)).per(User::PER_PAGE) }
			format.xls
		end
	end

	# Actualización del usuario seleccionado
	def update
		if needs_password?(params[:user])
			if @user.update_attributes(params[:user])
				redirect_to admin_users_path, notice: t("admin.users.updated")
			else
				render :action => :edit
			end
		else
			if @user.update_without_password(params[:user])
				redirect_to admin_users_path, notice: t("admin.users.updated")
			else
				render :action => :edit
			end
		end
	end


	protected

		# Necesito actualizar contraseña ?
	    def needs_password?(_params)
	      !_params[:password].blank?
	    end

	    # Setter de usuario
		def set_user
			@user = User.find(params[:id])
		end

end