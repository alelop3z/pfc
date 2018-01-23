class CommentsController < ApplicationController

	# Acciones previas a borrado de comentario
	before_action :set_comment, only: [:destroy, :edit, :mark_as_offensive, :show, :update]
	before_action :owner?, only: [:destroy, :edit, :update]

	# Borrado de un comentario
	def destroy
		@comment.destroy

		respond_to do |format|
			format.html { redirect_to :back }
			format.json { head :no_content }
		end
	end

	# Edición de un comentario
	def edit
		respond_to do |format|
			format.html
			format.js
			format.json { render :json => { :comment => @comment.as_json(json: 'wall') }}
		end
	end

	# Marcar un comentario como ofensivo
	def mark_as_offensive
		@comment.mark_as_offensive

		respond_to do |format|
			format.html
			format.js
			format.json { render :json => { :comment => @comment.as_json(json: 'wall') }}
		end
	end

	# Visualización de un comentario
	def show
		respond_to do |format|
			format.html
			format.js
			format.json { render :json => { :comment => @comment.as_json(json: 'wall') }}
		end
	end

	# Actualización de un comentario
	def update
		if @comment.update_attributes(params[:comment])
			respond_to do |format|
				format.html 
				format.json { render :json => { comment: @comment.as_json(json: 'wall') }}
			end
		else
			respond_to do |format|
		        format.html { render action: :edit }
		        format.json { render :json => { comment: @comment.errors, status: :unprocessable_entity }}
		      end
		end
	end


	protected

		# Es el propietario del comentario?
		def owner?
			redirect_to root_path if @comment.blank? || (@comment && @comment.user_id != @current_user._id)			
		end

		# Setter de comentario para acciones indicadas
		def set_comment
			@comment = Comment.find(params[:id])
		end

end