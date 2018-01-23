require 'nokogiri'
require 'open-uri'
require 'uri'

class Import

  attr_reader :description
  attr_reader :difficulty
  attr_reader :distance
  attr_reader :duration
  attr_reader :location
  attr_reader :name
  attr_reader :points
  attr_reader :url

  # Si get == true automaticamente se obtiene la información de la url introducida al crear el objeto
	def initialize(_url, get)
		@url = _url

		if get and !_url.blank?
			get_info()
		end
	end

	# Parsea la página que hayamos introducido en busca de toda la información
	def get_info()
		@doc = Nokogiri::HTML(open(url))
		parse_description
    parse_name
    parse_points
	end

	private

    # Parsear descripción del HTML
    def parse_description
      @description = @doc.css("div[id=description]").text.strip.gsub("\r\n", "<br />")
    end

    # Parsear dificultad del HTML
  	def parse_difficulty
  		@difficulty = @doc.css("h1[itemprop=name] div[class=overflow]").text.strip
  	end

    # Parsear distancia del HTML
  	def parse_distance
  		@distance = @doc.css("span[id=display-address]").text.strip
  	end

    # Parsear duración del HTML
  	def parse_duration
  		@duration = @doc.css("div[id=description_text_wrapper]").text.strip
  	end

    # Parsear nombre del HTML
  	def parse_name
  		@name = @doc.css("[class=breadcrumb-title] h1").text.strip
  	end

    # Parsear puntos del HTML
    def parse_points
      @points = []
      _track = nil

      @doc.css("script").each do |_script|
        _track = _script.text if _script.text.include?("var trinfo")
      end

      _latitud = _track.split("lat: ")[1].split("]")[0].split(",")
      _longitud = _track.split("lng: [")[1].split("]")[0].split(",")
      _elevacion = _track.split("ele: [")[1].split("]")[0].split(",")

      _latitud.each_with_index do |_lat, i|
        @points << {"lat" => _latitud[i].to_f, "lng" => _longitud[i].to_f, "ele" => _elevacion[i].to_f}
      end

      @points
    end

end
