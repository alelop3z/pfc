class Conversation

  # Librerías
  include Mongoid::Document
  include Mongoid::Timestamps

  # Constantes
  PER_PAGE = 25

  # Campos
  field :deleted_by_users, type: Array, default: []
  field :from, type: String
  field :last_to, type: String
  field :last_to_message_at, type: DateTime
  field :to, type: String
  field :unreads, type: Hash, default: {}
  field :users, type: Array, default: []

  # Indices
  index({ :deleted_by_users => 1 }, { :name => "deleted_by_users_conversations_index", :background => true })
  index({ :last_to => 1 }, { :name => "last_to_conversations_index", :background => true })
  index({ :last_to => 1, :last_to_message_at => -1}, { :name => "last_to_last_to_message_at_conversations_index", :background => true })
  index({ :users => 1 }, { :name => "users_conversations_index", :background => true })
  index({ :users => 1, :last_to_message_at => -1}, { :name => "users_last_to_message_at_conversations_index", :background => true })

  # Relaciones
  embeds_many :messages, :order => :created_at.asc, :cascade_callbacks => true

  # Callbacks
  after_destroy :fix_users
  after_save :set_count_user_messages
  before_create :set_unreads_messages
  before_validation :set_users

  # Validates
  validates :from, presence: true
  validates :to, presence: true
  validates :users, presence: true

  # Métodos
  # Búsqueda de comentarios a partir de parámetros enviados
  def self.search(_params)
    _conversations = self.only(:_id, :users)
    _conversations = _conversations.where(:users.in => params[:user_id]) unless params[:user_id].blank?

    _conversations.desc(:created_at)
  end

  # Recibe el texto del mensaje y el identificador del usuario que escribe el mensaje
  def add_msg(msg, _from)
    self.deleted_by_users = []
    self.last_to_message_at = Time.now
    self.unreads = {:from => 0, :to => 0} if self.unreads.blank?
    self.updated_at = Time.now

    if _from.to_s == self.from.to_s
      self.unreads[:to] += 1
      self.last_to = self.to

      msg[:from] = 'from'
    else
      self.unreads[:from] += 1
      self.last_to = self.from

      msg[:from] = 'to'
    end

    message = self.messages.new(msg)

    # Si el mensaje se guarda bien actualizo los valores de la conversación 
    if message.save
      self.save
    end
  end

  def as_json(options = {})
    case options[:json]
      when "wall"
        # JSON para pintar en el muro las conversaciones
        return super(:only => [:last_to, :last_to_message_at, :unreads], :methods => [:id_to_s, :last_message, :msgs, :user_from, :user_to])
    end

    return super
  end

  # Eliminar mensaje del usuario (archivar mensaje)
  def delete_by_user(_user)
    if !self.deleted_by_users.include?(_user.id.to_s)
      self.deleted_by_users << _user.id.to_s
      self.save

      _user.set_count_messages
    end
  end

  # Identificador en formato texto
  def id_to_s
    self._id.to_s
  end

  # Devuelvo el último mensaje que tenga la conversación
  def last_message
    self.messages.desc(:created_at).limit(1).first.text rescue nil
  end

  # Marcar como leído
  def mark_as_read_by(_user)
    if from == _user.id.to_s
      self.unreads[from] = 0
      self.req_unreads[from] = 0
    elsif to == _user.id.to_s
      self.unreads[to] = 0
      self.req_unreads[to] = 0
    end

    self.save
    self.set_count_user_messages
  end

  # Mensajes
  def msgs
    self.messages.as_json
  end

  # Usuario que ha enviado el mensaje
  def user_from
    _user = User.only(:_id, :avatar_file_name, :avatar_updated_at, :name).find(from) rescue User.new

    return {:avatar => _user.avatar, :id_to_s => _user.id_to_s, :name => _user.name}
  end

  # Usuario al que se le ha enviado el mensaje
  def user_to
    _user = User.only(:_id, :avatar_file_name, :avatar_updated_at, :name).find(to) rescue User.new

    return {:avatar => _user.avatar, :id_to_s => _user.id_to_s, :name => _user.name}
  end

  protected

    # Arreglar el número de mensajes de los usuarios tras eliminar una conversación
    def fix_users
      self.set_count_user_messages
    end

    # Settear número de mensajes de un usuario, del inbox, sent, archived y
    def set_count_user_messages
      self.users.each do |user|
        User.find(user).set_count_messages rescue nil
      end
    end

    # Setter de mensajes sin leer
    def set_unreads_messages
      self.unreads = {:from => 0, :to => 0}
    end

    # Setter de los usuarios participantes de la conversación
    def set_users
      self.users = [self.from.to_s, self.to.to_s]
    end

end
