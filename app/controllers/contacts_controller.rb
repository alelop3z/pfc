class ContactsController < ApplicationController

	def contact
		@contact = Contact.new

		respond_to do |format|
			format.html
			format.js
		end
	end

	def send_contact
		@contact = Contact.new(params[:contact])

		if @contact.valid?
			Thread.new do
				ContactMailer.send_contact(@contact).deliver
			end

			respond_to do |format|
				format.html
				format.js
			end
		else
			respond_to do |format|
				format.html { render :action => :index }
				format.js { render :action => :index_ko }
			end
		end
	end

end