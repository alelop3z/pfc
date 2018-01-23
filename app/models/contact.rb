class Contact

	# Librerías de validaciones
	include ActiveModel::Validations
	include ActiveModel::Conversion
	extend ActiveModel::Naming
	extend ActiveModel::Translation

	# Atributos virtuales
	attr_accessor :comments, :email, :name, :terms_of_service, :subject

	# Validaciones
	validates :comments, presence: true
	validates :email, presence: true, format: {with: /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, multiline: true}
	validates :name, presence: true
	validates :subject, presence: true
	validates :terms_of_service, acceptance: true, allow_nil: false


	# Methods
	def initialize(params = {})
		self.comments = params[:comments]
		self.email = params[:email]
		self.name = params[:name]
		self.terms_of_service = params[:terms_of_service]
		self.subject = params[:subject]
	end

end