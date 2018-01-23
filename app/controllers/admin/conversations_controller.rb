class Admin::ConversationsController < ApplicationController

	before_filter :authorize_admin
	before_filter :set_conversation, only: [:destroy, :edit, :update]

	def index
		@conversations = Conversation.search(params[:search]).page((params[:page] || 1)).per(PER_PAGE)
	end

	def edit
	end

	def update
		if @conversation.update_attributes(params[:conversation])
			redirect_to admin_conversations_path, notice: t("admin.conversations.updated")
		else
			render :action => :edit
		end
	end

	def destroy
		if @conversation.destroy
			flash[:notice] = t("admin.conversations.destroyed")
		else
			flash[:error] = t("admin.conversations.not_destroyed")
		end

		redirect_to admin_conversations_path
	end


	protected

		def set_conversation
			@conversation = Conversation.find(params[:id])
		end

end