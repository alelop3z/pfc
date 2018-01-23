class Comment

  # Librerías de Mongo
  include Mongoid::Document
  include Mongoid::Timestamps

  # Constantes
  PER_PAGE = 25

  # Relaciones
  belongs_to :user

  # Campos
  field :participant_ids, type: Array, default: []
  field :object_id, type: String
  field :object_type, type: String
  # Mayor de 0 es un estado no válido completamente, inicialmente sólo disponemos de 0 (válido) ó 1 (ofensivo) 
  field :status, type: Integer, default: 0 
  field :text, type: String

  # Callbacks
  before_save :set_participant_ids

  # Indices
  index({ :participant_ids => 1 }, { :name => "participant_ids_index", :background => true })

  # Validaciones
  validates :user_id, presence: {message: I18n.t("comments.user_id.presence")}
  validates :text, presence: {message: I18n.t("comments.text.presence")}
  validates :text, length: { maximum: 256, message: I18n.t("comments.text.length")}


  # Methods
  # Búsqueda de comentarios a través de parámetros
  def self.search(_params = {})
    _comments = self.only(:_id, :created_at, :object_type, :participant_ids, :status, :text, :user_id)

    if _params and !_params[:user].blank?
      _users = User.only(:_id, :email, :name).or({:name => /.*#{_params[:user]}.*/i}, {:email => /.*#{_params[:user]}.*/i}).collect(&:_id).collect(&:to_s)
      _comments = _comments.where(:participant_ids.in => _users)
    end

    _comments = _comments.where(:status => 1) if _params && _params[:mark_as_offensive]
    _comments.desc(:created_at)
  end

  # Lista de comentarios en formato CSV
  def self.to_csv(_comments = nil, _columns = nil, options = {}, params = {})
    _columns ||=  ["_id", "text"]
    _comments ||= Comment.desc(:created_at)

    CSV.generate(options) do |csv|
      csv << _columns

      _comments.each do |_comment|
        csv << _comment.attributes.values_at(*_columns)
      end
    end
  end

  # Metodo As_json sobreescrito
  def as_json(options = {})
    case options[:json]
      when "wall"
        return super(:only => [:created_at, :text], :methods => [:from, :id_to_s, :timestamp, :type_comment, :unix_timestamp, :user_id_to_s])
    end

    super.merge(options)
  end

  # Usuario que ha enviado el comentario
  def from
    _from = User.only(:_id, :avatar_file_name, :avatar_updated_at, :name).find(self.user_id) rescue nil

    if _from
      {:image => _from.avatar.url(:detail), :name => _from.name}
    end
  end

  # Elemento identificativo de la base de datos (JSON)
  def id_to_s
    self._id.to_s
  end

  # Comprueba si un comentario es de tipo comentario
  def is_comment?
    self.object_type.downcase.to_s == "comment" || self.object_type.blank?
  end

  # Comprueba si un comentario es de tipo comentario
  def is_event?
    self.object_type.downcase.to_s == "event"
  end

  # Comprueba si el comentario es ofensivo
  def is_offensive?
    self.status == 1
  end

  # Comprueba si un comentario es de tipo comentario
  def is_route?
    self.object_type.downcase.to_s == "route"
  end

  # Marcar comentario como ofensivo
  def mark_as_offensive
    self.update_attribute(:status, 1)
  end

  # Hora de creación del comentario (formato UNIX)
  def timestamp
    # self.created_at.to_i
    self.created_at.getutc.iso8601
  end

  # Hora de creación del comentario (formato UNIX)
  def unix_timestamp
    self.created_at.to_i
  end

  # Método para indicar el tipo de comentario
  def type_comment
    self.object_type.blank? ? "comment" : self.object_type
  end

  # Identificador del usuario
  def user_id_to_s
    self.user_id.to_s
  end

  # Comentarios de un objeto en concreto
  def self.get_object_comments(_object, _timestamp)
    comments = Comment.where(:object_type => _object.class.to_s, :object_id => _object.id_to_s)
    comments = comments.where(:created_at.gt => "#{Time.at(_timestamp.to_i)}") if _timestamp
    comments = comments.desc(:created_at).limit(25)
  end


  # Comentarios del muro de un usuario
  def self.user_wall(_user, _timestamp = nil)
    comments = Comment.or({:object_type => nil}, {:object_type => "Comment"}).any_of([:participant_ids.in => [_user._id.to_s]], [:participant_ids.in => _user.follow_ids])
    comments = comments.where(:created_at.lt => "#{Time.at(_timestamp.to_i)}") if _timestamp
    comments = comments.desc(:created_at).limit(10)
  end

  # Comentarios realizados por el usuario
  def self.user_tweets(_user, _timestamp = nil)
    comments = Comment.or({:object_type => nil, :user_id => _user.id_to_s}, {:object_type => "Comment", :object_id => _user.id_to_s})
    comments = comments.where(:created_at.lt => "#{Time.at(_timestamp.to_i)}") if _timestamp
    comments = comments.desc(:created_at).limit(10)
  end

  protected

    # Setter de los participantes del comentario
    def set_participant_ids
      self.participant_ids = []
      self.participant_ids << user_id.to_s
    end

end
