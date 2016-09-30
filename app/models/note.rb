class Note
  include MongoidBase

  strip_attributes

  field :message,        type: String
  field :type,     type: Symbol, default: :general

  belongs_to :author, class_name: 'User'
  belongs_to :user
  belongs_to :order

  validates :title,       presence: true

  scope :unreads, -> { where({:read_at => nil}) }

end
