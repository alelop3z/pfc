class Config

	# Librerías
	include Mongoid::Document
	include Mongoid::Timestamps

	# Constantes
	PER_PAGE = 25

	# Fields
	field :key, type: String
	field :value, type: String

	# Validaciones
	validates :key, presence: true
	validates :value, presence: true

	
	# Methods 
	def self.method_missing(id, *args) 
		self.where(:key => id).first.value
	end

end