class Admin::CommentsController < ApplicationController

	# Filtros previos a las acciones indicadas
	before_filter :authorize_admin
	before_filter :set_comment, only: [:destroy, :edit, :update]

	# Uso de layout administrador para las acciones aquí incluidas
	layout 'admin'

	# Eliminar comentario seleccionado
	def destroy
		if @comment.destroy
			respond_to do |format|
				format.html { 
					redirect_to admin_comments_path, notice: t("admin.comments.destroyed")
					}
				format.js {}
			end	
		else
			redirect_to admin_comments_path, error: t("admin.comments.dont_destroy")
		end
	end

	# Edición de comentario
	def edit
	end

	# Listado de comentarios
	def index
		@comments = Comment.search(params[:comment])

		respond_to do |format|
			format.csv { send_data @comments.to_csv }
			format.html { @comments = @comments.page((params[:page] || 1)).per(Comment::PER_PAGE) }
			format.xls
		end
	end

	# Actualización del comentario seleccionado
	def update
		if @comment.update_attributes(params[:comment])
			redirect_to admin_comments_path, notice: t("admin.comments.updated")
		else
			render :edit
		end
	end


	protected

		# Setter de comentario a partir del id del comentario
		def set_comment
			@comment = Comment.find(params[:id])
		end

end 