class Message

  # Librerías de Mongoid
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos del documento
  field :from, type: String # es 'from' o 'to' dependiendo de quien haya escrito la conversación
  field :text, type: String

  # Relaciones
  embedded_in :conversation, :inverse_of => :messages

  # Validaciones
  validates :from, presence: true
  validates :text, presence: true

  # Callbacks
  before_save :set_html_message


  protected

    # Setter de texto limpiando caracteres ilegales
    def set_html_message
      self.text = self.text.gsub("\r\n", "<br />")
    end

end
