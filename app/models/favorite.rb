class Favorite

  # Librerías
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :object_type, type: String
  field :object_id, type: BSON::ObjectId

  # Relaciones
  belongs_to :user


end