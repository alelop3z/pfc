class Admin::EventsController < ApplicationController

	before_filter :authorize_admin
	before_filter :set_event, only: [:destroy, :edit, :update]

	# Layout de administracion
	layout 'admin'

	# Create event
	def create
		@event = Event.new(params[:event])

		if @event.save
			redirect_to admin_events_path, notice: t("admin.events.created")
		else
			render :new
		end
	end

	# Destroy event
	def destroy
		if @event.destroy
			respond_to do |format|
				format.html { 
					redirect_to admin_events_path, notice: t("admin.events.destroyed")
					}
				format.js {}
			end
		else
			redirect_to admin_events_path, error: t("admin.events.dont_destroy")
		end
	end

	def edit
		@markers = Gmaps4rails.build_markers(@event) do |point, marker|
			marker.lat point.lat
			marker.lng point.lng
		end
	end

	def index
		@events = Event.search(params[:event])

		respond_to do |format|
			format.csv { send_data @events.to_csv }
			format.html { @events = @events.page((params[:page] || 1)).per(Event::PER_PAGE) }
			format.xls
		end
	end

	def new
		@route = Route.new
	end

	def update
		if @event.update_attributes(params[:event])
			redirect_to admin_events_path, notice: t("admin.events.updated")
		else
			render :edit
		end
	end

	protected

		def set_event
			@event = Event.find(params[:id])
		end

end