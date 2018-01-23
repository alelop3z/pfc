class Event

  # Librerías de Mongo
  include Mongoid::Document
  include Mongoid::Paperclip
  include Mongoid::Slug
  include Mongoid::Timestamps

  # Constantes
  PER_PAGE = 25

  # Campos
  field :address, type: String
  field :allow_comments, type: Boolean, default: true
  field :description, type: String
  field :event_type, type: Integer, default: 0
  field :init_date, type: DateTime
  field :last_visit_at, type: DateTime
  field :location, type: Array
  field :name, type: String
  field :private, type: Boolean, default: false
  field :static_image, type: String
  field :summary, type: String
  field :url, type: String

  # Indices
  index({:location => "2d" }, { :min => -200, :max => 200 })

  # Relaciones
  belongs_to :user

  # Plugins
  slug :name

  # Validaciones
  validates :address, presence: {message: I18n.t("events.address.presence")}
  validates :description, presence: {message: I18n.t("events.description.presence")}
  validates :event_type, presence: {message: I18n.t("events.event_type.presence")}
  validates :init_date, presence: {message: I18n.t("events.init_date.presence")}
  validates :location, presence: {message: I18n.t("events.location.presence")}
  validates :name, presence: {message: I18n.t("events.name.presence")}

  # Callbacks
  before_validation :check_valid_date

  # Comprobación de fecha válida
  def check_valid_date
    unless self.init_date.is_a?(Date)
      self.errors.add(:init_date, I18n.t("events.init_date.invalid_date"))
    end
  end

  # Atributos virtuales
  attr_accessor :latitude, :longitude

  # Callbacks
  before_validation :set_location

  # Methods
  # Busqueda de eventos a través de parámetros
  def self.search(_params = {})
    if !_params.blank? && _params[:lat_ne] && _params[:lat_sw] && _params[:lng_ne] && _params[:lng_sw]
      point_ne = [_params[:lng_ne].to_f, _params[:lat_ne].to_f]
      point_nw = [_params[:lng_sw].to_f, _params[:lat_ne].to_f]
      point_se = [_params[:lng_ne].to_f, _params[:lat_sw].to_f]
      point_sw = [_params[:lng_sw].to_f, _params[:lat_sw].to_f]
      polygon = [point_ne, point_nw, point_sw, point_se, point_ne]
    end

    _events = Event.all
    
    # Eventos no privados o lo que nos llegue como parámetro
    if !_params.blank? && !_params[:private].blank?
      _events = _events.where(:private => _params[:private])
    else
      _events = _events.where(:private => false)
    end

    # Tengo que hacer la consulta manualmente ya que no funciona el método within_box
    _events = _events.geo_spacial(:location.within_polygon => [polygon]) if polygon

    # Control de eventos por nombre, fecha de inicio o tipo de evento
    _events = _events.where(:name => /#{_params[:text]}/i) if !_params.blank? && !_params[:text].blank?
    _events = _events.where(:init_date.gte => _params[:from]) if !_params.blank? && !_params[:from].blank?
    _events = _events.where(:init_date.lte => _params[:to]) if !_params.blank? && !_params[:to].blank?
    _events = _events.where(:event_type.in => _params[:event_type].split(",")) if !_params.blank? && !_params[:event_type].blank?
    
    _events.desc(:init_date)
  end

  # Lista de eventos en formato CSV
  def self.to_csv(_events = nil, _columns = nil, options = {}, params = {})
    _columns ||=  ["_id", "name", "init_date", "url"]
    _events ||= Event.desc(:created_at)

    CSV.generate(options) do |csv|
      csv << _columns

      _events.each do |_event|
        csv << _event.attributes.values_at(*_columns)
      end
    end
  end

  # Sobreescribir método de generación de JSON
  def as_json(options = {})
    case options[:json]
      when "wall"
        return self.as_json(:only => [:address, :name, :static_image, :summary], :methods => [:id_to_s, :ico_event_type, :locale_init_date, :user_id_to_s])
      when "edit"
        return self.as_json(:only => [:address, :description, :event_type, :locale_init_date, :latitude, :longitude, :name, :summary, :url], :methods => [:id_to_s, :ico_event_type, :is_commentable, :is_private, :locale_init_date, :user_id_to_s])
      when "near_events"
        return self.as_json(:only => [:address, :init_date, :name, :summary], :methods => [:id_to_s, :ico_event_type, :is_commentable, :is_private, :locale_init_date, :user_id_to_s])
      when "show"
        return self.as_json(:only => [:address, :description, :init_date, :name, :summary], :methods => [:id_to_s, :ico_event_type, :is_commentable, :is_private, :locale_init_date, :user_id_to_s])
    end
    
    super.merge(options)
  end

  # Método que devuelve el tipo de ruta
  def get_type
    Main::TYPES[self.event_type].first
  end

  # Descripcion e icono de tipo de ruta
  def ico_event_type(_gmaps = false)
    _event_type = {}
    _event_type["icon"] = self.set_icon_event_type(_gmaps ? "gmaps" : "routes")
    _event_type["description"] = self.set_description_event_type
    _event_type
  end

  # Identificador del evento
  def id_to_s
    self._id.to_s
  end

  # Fecha traducida según el idioma del usuario
  def locale_init_date
    I18n.l(self.init_date, format: :datepicker) rescue nil
  end

  # Devuelve 1 si es comentable, 0 en caso de que no lo sea
  def is_commentable
    self.allow_comments ? "1" : "0"
  end

  # Devuelve 1 en caso de ser un evento privado o 0 en caso contrario
  def is_private
    self.private ? "1" : "0"
  end

  # Latitud de la localización
  def lat
    self.location.last rescue nil
  end

  # Longitud de la localización
  def lng
    self.location.first rescue nil
  end

  # Posición del punto del evento en el mapa
  def marker
    {"lat" => lat, "lng" => lng} rescue nil
  end

  # Actualizar la visita a la ruta
  def update_last_visit_at
    self.update_attribute(:last_visit_at, Time.now)
  end

  # Imagen estática
  def static_image
    "http://maps.googleapis.com/maps/api/staticmap?size=60x60&sensor=false&markers=color:orange%7C#{lat},#{lng}&zoom=11"
  end

  # Identificador del usuario
  def user_id_to_s
    self.user_id.to_s
  end

  # Tipo de eventos disponibles
  def self.type_events
    Main::TYPES.map{|x| [x.first, x.last]}
  end


  protected

    # Setter de la descripción del tipo de ruta
    def set_description_event_type
      case event_type
        when 0
          return I18n.t("main.event_types.bmx")
        when 1
          return I18n.t("main.event_types.ciclocross")
        when 5
          return I18n.t("main.event_types.mountain_bike")
        when 6
          return I18n.t("main.event_types.road")
      end
    end

    # Setter del icono del tipo de ruta
    def set_icon_event_type(_route = "routes")
      case event_type
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

    # Settear localización a partir de latitud y longitud pulsada
    def set_location
      self.location = [self.longitude.to_f, self.latitude.to_f] if self.latitude && self.longitude
    end

end
