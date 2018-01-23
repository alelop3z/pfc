class Admin::DashboardController < ApplicationController

	# Filtros previos a las acciones indicadas
	before_filter :authorize_admin

	# Uso de layout administrador para las acciones aquí incluidas
	layout 'admin'

	# Listado de ultimos elementos
	# de los elementos creados en el sistema
	def index
		@comments = Comment.only(:_id, :created_at, :status, :user_id, :text).desc(:created_at).limit(5)
		@events = Event.only(:_id, :_slugs, :event_type, :finish_date, :init_date, :name).desc(:created_at).limit(5)
		@routes = Route.only(:_id, :_slugs, :allow_comments, :created_at, :difficulty, :location, :name, :private, :route_type, :static_image, :static_trackpoints, :summary, :user_id).desc(:created_at).limit(5)
		@users = User.only(:_id, :created_at, :email, :name).desc(:created_at).limit(5)
	end

end 