class User

  # Mongo Library
  include Mongoid::Document
  include Mongoid::Paperclip
  include Mongoid::Search
  include Mongoid::Timestamps

  # Constantes
  PER_PAGE = 25

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, :type => String, :default => ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  # Other fields
  field :about_me, type: String
  field :birthday, type: DateTime
  field :count_messages, type: Hash, default: {}
  field :follow_ids, type: Array, default: []
  field :follower_ids, type: Array, default: []
  field :name, type: String
  field :privacity, type: Integer, default: 0
  field :roles, type: Array, default: []
  field :tutorial_seen_at, type: DateTime
  field :web_page, type: String

  # Atributos virtuales
  attr_accessor :password, :password_confirmation

  # Relaciones
  has_many :comments, dependent: :destroy
  has_many :conversations, dependent: :destroy, foreign_key: :from
  has_many :events, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :routes, dependent: :destroy

  # Plugins
  has_mongoid_attached_file :avatar, :styles => {:thumb => ["32x32#", :jpg], :list => ["48x48#", :jpg], :detail => ["73x73#", :jpg], :large => ["256x256#", :jpg]}
  search_in :name

  # Validations
  validates :name, :presence => true
  validates_attachment_content_type :avatar, :content_type => %w(image/jpeg image/jpg image/png)

  # Methods
  # Search users by params
  def self.search(_params = {})
    _users = self.all
    _users = _users.where(:created_at.gte => _params[:from]) if _params && _params[:from]
    _users = _users.where(:created_at.lte => _params[:to]) if _params && _params[:to]
    _users = _users.where(:name => /#{_params[:text]}/i) if _params && _params[:text]
    _users = _users.where(:email => /#{_params[:email]}/i) if _params && _params[:email]

    _users
  end

  # Lista de usuarios en formato CSV
  def self.to_csv(_users = nil, _columns = nil, options = {}, params = {})
    _columns ||=  ["_id", "created_at", "email", "name"]
    _users ||= User.desc(:created_at)

    CSV.generate(options) do |csv|
      csv << _columns

      _users.each do |_user|
        csv << _user.attributes.values_at(*_columns)
      end
    end
  end

  # Añadir un favorito
  def add_favorite(_id, _type)
    self.favorites.create(:object_type => _type, :object_id => _id)
    self.save
  end

  # Add follow to user
  def add_follow(_user)
    unless self.follow_ids.include?(_user.id_to_s)
      self.follow_ids << _user.id_to_s
      self.save
    end

    unless _user.follower_ids.include?(self.id_to_s)
      _user.follower_ids << self.id_to_s
      _user.save
    end
  end

  # Devuelve información del usuario
  def admin
    admin?
  end

  # Admin user ?
  def admin?
    self.roles.include?("admin")
  end

  # User types JSON
  def as_json(options = {})
    case options[:json]
      # Para los tipos amistad
      when "friendship"
        return super(:only => [:about_me, :name], :methods => [:id_to_s, :photo])
      # Para el menú superior
      when "reload_menu"
        return super(:only => [:count_messages])
      # Para búsqueda de usuarios de la cabecera
      when "search"
        return super(:only => [:name], :methods => [:id_to_s, :photo])
      # Muro de usuario
      when "wall"
        return super(:only => [:follow_ids, :follower_ids, :name], :methods => [:event_favorites, :id_to_s, :num_conversations, :num_events, :num_favorites, :num_routes, :photo, :route_favorites])
      when "all"
        return super(:methods => [:id_to_s, :num_events, :num_routes, :photo])
    end

    super.merge(options)
  end

  # Conversation between users
  def conversation(_user_id)
    _conversation = Conversation.where(:deleted_by_users.nin => [self.id_to_s], :users.all => [self.id_to_s, _user_id]).first
    _conversation = Conversation.create(:from => self.id_to_s, :to => _user_id) if _conversation.blank?
    
    _conversation
  end

  # Conversations from user
  def conversations
    Conversation.where(:deleted_by_users.nin => [self.id_to_s], :users.in => [self.id_to_s]).desc(:last_to_message_at)
  end

  # Eliminar un favorito
  def del_favorite(_id, _type)
    self.favorites.where(:object_type => _type, :object_id => _id).destroy
  end

  # Remove followers
  def del_follow(_user)
    if self.follow_ids.include?(_user.id_to_s)
      self.follow_ids.delete(_user.id_to_s)
      self.save
    end
  end

  # Friendships
  def follows
    @users = User.where(:_id.in => self.follow_ids)
  end

  # Friendships
  def followers
    @users = User.where(:_id.in => self.follower_ids)
  end

  # ID to string
  def id_to_s
    self._id.to_s
  end

  # Welcome mail
  def mail_welcome
    Thread.new do 
      UserMailer.welcome(self).deliver
    end
  end

  # Número de conversaciones
  def num_conversations
    self.count_messages["inbox"]
  end

  # Número de rutas
  def num_events
    self.events.count
  end

  # Número de favoritos
  def num_favorites
    self.favorites.count
  end

  # Número de rutas
  def num_routes
    self.routes.count
  end

  # User photo
  def photo
    if avatar_file_name.blank?
      "/avatars/detail/missing.png"
    else
      avatar.url(:large)
    end
  end

  # Elementos favoritos
  # Según el parámetro pasado devolverá la clase que elijamos
  def objects_favorites(_type = "Route")
    _array = self.favorites.where(:object_type => _type).desc(:created_at).collect(&:object_id)
    _type.constantize.where(:_id.in => _array)
  end

  def event_favorites
    self.favorites.where(:object_type => "Event").collect(&:object_id).collect(&:to_s)
  end

  def route_favorites
    self.favorites.where(:object_type => "Route").collect(&:object_id).collect(&:to_s)
  end

  # Setter del número de conversaciones del usuario
  def set_count_messages
    _conversations = {}
    _conversations["archived"] = Conversation.where(:deleted_by_users.in => [self.id_to_s], :users.in => [self.id_to_s]).count
    _conversations["inbox"] = Conversation.where(:deleted_by_users.nin => [self.id_to_s], :users.in => [self.id_to_s]).count
    _conversations["unreads"] = Conversation.where(:deleted_by_users.nin => [self.id_to_s], :last_to => self.id_to_s, :users.in => [self.id_to_s]).ne("unreads.#{self.id_to_s}" => 0).count

    self.update_attribute(:count_messages, _conversations)
  end

end
