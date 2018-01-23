require 'tempfile'

class Route

  # Librerías de Mongo
  include Mongoid::Document
  include Mongoid::Paperclip
  include Mongoid::Slug
  include Mongoid::Timestamps

  # Constantes
  PER_PAGE = 25

  # Campos
  field :allow_comments, type: Boolean, default: true
  field :description, type: String
  field :difficulty, type: Integer, default: 0 # Dificultad de la ruta
  field :distance, type: Float  
  field :downloads, type: Integer, default: 0 # Número de descargas que se han realizado
  field :duration, type: Hash, default: {}
  field :gpx, type: String # URL donde se almacena el fichero de la ruta
  field :last_download_at, type: DateTime # Última fecha en la que se ha descargado el fichero de la ruta
  field :last_visit_at, type: DateTime # Última visita a la ruta
  field :location, type: Array # Punto inicial de la ruta (lat, lng)
  field :name, type: String
  field :points, type: Array, default: [] # Array con todos los puntos de la ruta
  field :private, type: Boolean, default: false # Privacidad de la ruta
  field :route_type, type: Integer, default: 0 # Tipo de ruta
  field :static_image, type: String # URL de la imagen estática en el sistema
  field :static_trackpoints, type: String
  field :summary, type: String # Resumen
  field :url, type: String # en caso de que se importe de una URL

  # Relaciones
  belongs_to :user
  # has_many :albums

  # Plugins
  has_mongoid_attached_file :gpx_file
  slug :name

  # Indices
  index({:location => "2d"}, { :background => true, :min => -200, :max => 200 })
  index({:privacity => 1}, {:background => true})

  # Validaciones
  # Paso 1
  validates_attachment :gpx_file, :presence => true, :content_type => {:content_type => %w(application/octet-stream)}, :if => :validate_gpx_file?
  # Paso 2
  validates :description, presence: true
  validates :difficulty, presence: true
  # validates :distance, presence: true
  validates :name, presence: true
  validates :route_type, presence: true

  # Callbacks
  # after_create :set_comment
  # after_destroy :remove_comment
  before_save :set_location
  before_save :set_static_points
  before_save :set_summary

  # Métodos
  # Búsqueda parametrizada
  def self.search(_params = {})
    if !_params.blank? && _params[:lat_ne] && _params[:lat_sw] && _params[:lng_ne] && _params[:lng_sw]
      point_ne = [_params[:lng_ne].to_f, _params[:lat_ne].to_f]
      point_nw = [_params[:lng_sw].to_f, _params[:lat_ne].to_f]
      point_se = [_params[:lng_ne].to_f, _params[:lat_sw].to_f]
      point_sw = [_params[:lng_sw].to_f, _params[:lat_sw].to_f]
      polygon = [point_ne, point_nw, point_sw, point_se, point_ne]
    end

    _routes = Route.all

    # Rutas no privadas o lo que nos llegue como parámetro
    if !_params.blank? && !_params[:private].blank?
      _routes = _routes.where(:private => _params[:private])
    else
      _routes = _routes.where(:private => false)
    end

    # Tengo que hacer la consulta manualmente ya que no funciona el método within_box
    _routes = _routes.geo_spacial(:location.within_polygon => [polygon]) if polygon
    _routes = _routes.where(:name => /#{_params[:text]}/i) if !_params.blank? && !_params[:text].blank?
    _routes = _routes.where(:difficulty.in => _params[:dif].split(",")) if !_params.blank? && !_params[:dif].blank?
    _routes = _routes.where(:route_type.in => _params[:route_type].split(",")) if !_params.blank? && !_params[:route_type].blank?
    
    _routes.desc(:created_at)
  end

  # Lista de eventos en formato CSV
  def self.to_csv(_routes = nil, _columns = nil, options = {}, params = {})
    _columns ||=  ["_id", "name", "distance", "duration"]
    _routes ||= Route.desc(:created_at)

    CSV.generate(options) do |csv|
      csv << _columns

      _routes.each do |_route|
        csv << _route.attributes.values_at(*_columns)
      end
    end
  end

  # Sobrescrito método json para devolver campos específicos para acciones específicas
  def as_json(options = {})
    case options[:json]
      when "wall"
        return super(:only => [:allow_comments, :created_at, :name, :static_image, :summary], :methods => [:get_difficulty, :get_route_type, :ico_route_type, :id_to_s, :is_commentable, :is_private, :user_id_to_s])
      when "markers"
        return super(:only => [:_id], :methods => [:lat, :lng])
      when "edit"
        return super(:only => [:description, :difficulty, :name, :route_type, :static_trackpoints], :methods => [:get_difficulty, :get_route_type, :ico_route_type, :id_to_s, :is_commentable, :is_private, :user_id_to_s])
      when "near_routes"
        return super(:only => [:created_at, :name, :static_image], :methods => [:get_difficulty, :get_route_type, :ico_route_type, :id_to_s, :is_private])
      when "show"
        return super(:only => [:description, :difficulty, :name, :route_type, :static_trackpoints], :methods => [:get_difficulty, :get_route_type, :ico_route_type, :id_to_s, :is_commentable, :is_private, :user_id_to_s])
    end
    
    super.merge(options)
  end

  # Primer punto de la ruta (inicio de la misma)
  def first_point
    self.points.first rescue nil
  end

  # Método para devolver la dificultad de la ruta
  def get_difficulty
    Main::DIFFICULTY[self.difficulty].first
  end

  # Método que devuelve la duración en formato horas : minutos : segundos
  def get_duration
    begin
      if self.duration[:hours] > 0 and self.duration[:minutes] > 0 and self.duration[:seconds] > 0
        [self.duration[:hours], self.duration[:minutes], self.duration[:seconds]].join(":")
      end
    rescue
      nil
    end
  end

  # Método que devuelve las elevaciones de los puntos seleccionados en el GPX o mapa
  def get_elevations
    _elevations = []

    self.points.each_with_index do |_point, i|
      _elevations << _point["ele"] if i % 5 == 0
    end

    _elevations
  end

  # Método que devuelve el tipo de ruta
  def get_route_type
    Main::TYPES[self.route_type].first
  end

  # Método que crea un fichero en formato GPX
  def gpx
    generate_gpx_file rescue nil
  end

  # Descripcion e icono de tipo de ruta
  def ico_route_type(_gmaps = false)
    _route_type = {}
    _route_type["icon"] = self.set_icon_route_type(_gmaps ? "gmaps" : "routes")
    _route_type["description"] = self.set_description_route_type
    _route_type
  end

  # Identificador del usuario
  def id_to_s
    self._id.to_s
  end

  # Devuelve 1 si es comentable, 0 en caso de que no lo sea
  def is_commentable
    self.allow_comments ? "1" : "0"
  end

  # Devuelve 1 en caso de estar lista para todos o 0 en caso contrario
  def is_private
    self.private ? "1" : "0"
  end

  # Último punto de la ruta (fin de la ruta)
  def last_point
    self.points.last
  end

  # Latitud de la localización
  def lat
    self.location.last
  end

  # Longitud de la localización
  def lng
    self.location.first
  end

  def parse_gpx_file
    unless self.gpx_file.blank?
      doc = Nokogiri::XML(open(self.gpx_file.path))
      self.name = doc.xpath("//xmlns:name").text
      self.description = doc.xpath("//xmlns:desc").text
      trackpoints = doc.xpath("//xmlns:trkpt")
      _points = []
      _static_points = []

      trackpoints.each_with_index do |trkpt, i|
        _points << {:ele => (trkpt.css("ele").text.to_f rescue 0), :lat => trkpt.xpath('@lat').to_s.to_f, :lng => trkpt.xpath('@lon').to_s.to_f, :time => (DateTime.parse(trkpt.css("time").text, "%Y-%m-%d %H:%M") rescue nil)}
        _static_points << [trkpt.xpath('@lat').to_s.to_f,trkpt.xpath('@lon').to_s.to_f] if i % mod == 0
      end

      # Guardo los puntos una vez que se ha parseado el fichero siempre que no llegue en blanco
      unless _points.blank?
        self.duration = split_duration(_points.last[:time] - _points.first[:time]) if !_points.last[:time].blank? and !_points.first[:time].blank?
        self.points = _points
        self.static_trackpoints = Polylines::Encoder.encode_points(_static_points)
        self.save
      end
    end

    # create_comment_route_created
  end

  # Settear la localización a partir del primer punto de la ruta
  def set_location(params = {})
    self.location = [self.first_point["lng"].to_f, self.first_point["lat"].to_f]
    self.save if params[:save]
  end

  # Setter de los puntos estáticos y del que pinta el mapa estático de Google
  def set_static_points(params = {})
    # Calculo los valores en los que dividiré según el número de puntos que tengamos en el sistema
    _mod = 1
    _mod = 4 if self.points.count >= 400
    _mod = 10 if self.points.count > 1000
    _mod = 30 if self.points.count > 2000
    _mod = 50 if self.points.count > 3000

    _static_points = []
    self.points.each_with_index do |_point, i|
      _static_points << [_point["lat"].to_f, _point["lng"].to_f] if i % _mod == 0
    end

    self.static_trackpoints = Polylines::Encoder.encode_points(_static_points)
    self.save if params[:save]
  end

  # Imagen estática
  def static_image
    "http://maps.googleapis.com/maps/api/staticmap?size=60x60&sensor=false&path=weight:3%7Ccolor:0xff4621%7Cenc:#{self.static_trackpoints}"
  end

  # Actualizar la descarga de la ruta
  def update_last_download_at
    self.update_attribute(:last_download_at, Time.now)
  end

  # Actualizar la visita a la ruta
  def update_last_visit_at
    self.update_attribute(:last_visit_at, Time.now)
  end

  # Metodo de usuario para el JSON
  def user_id_to_s
    self.user.id_to_s
  end

  # Validar GPX 
  def validate_gpx_file?
    return false unless self.points.blank?
    return true if self.url.blank? && self.points.blank?
  end

  protected

    # Generación de un fichero GPX
    def generate_gpx_file
      File.open([Rails.root, "public", "#{self.id_to_s}.gpx"].join("/"), "w") do |file|
        file.puts('<?xml version="1.0" encoding="UTF-8"?>')
        file.puts('<gpx creator="VEB - http://www.voyenbici.com" version="1.1" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">')
        file.puts('<trk>')
        file.puts('<name>' + self.name + '</name>')
        file.puts('<cmt>' + self.description + '</cmt>')
        file.puts('<desc>' + self.description + '</desc>')
        file.puts('<trkseg>')

        self.points.each do |point|
          file.puts('<trkpt lat="' + point["lat"].to_s + '" lon="' + point["lng"].to_s + '">')
          file.write('<ele>' + point["ele"].to_s + '</ele>') if point["ele"]
          file.write('<time>' + point["time"].to_s + '</time>') if point["time"]
          file.write('</trkpt>')
        end

        file.puts('</trkseg>')
        file.puts('</trk>')
        file.puts('</gpx>')

        file
      end

      true
    end
    
    # Setter de la descripción del tipo de ruta
    def set_description_route_type
      case route_type
        when 0
          return "Rutas BMX"
        when 1
          return "Rutas de CicloCross"
        when 5
          return "Rutas Mountain Bike"
        when 6
          return "Rutas de carretera"
      end
    end

    # Setter del icono del tipo de ruta
    def set_icon_route_type(_route = "routes")
      case route_type
        when 0
          return "/assets/#{_route}/ico_bmx.png"
        when 1
          return "/assets/#{_route}/ico_ciclocross.png"
        when 5
          return "/assets/#{_route}/ico_mtb.png"
        when 6
          return "/assets/#{_route}/ico_carretera.png"
      end
    end

    # Setter de resumen a partir de los comentarios añadidos
    def set_summary
      self.summary = self.description[0..80]
      self.summary += " ..." if self.description.length > 80
    end

    # División en tiempo
    def split_duration(_time)
      _duration = {}
      _duration[:hours] = (_time / 3600).to_i
      _duration[:minutes] = ((_time % 3600) / 60).to_i
      _duration[:seconds] = ((_time % 3600) % 60).to_i
      _duration
    end

end
