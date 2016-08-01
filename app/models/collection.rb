class Collection
  include MongoidBase

  strip_attributes

  field :name,    type: String
  field :img,     type: String
  field :public,  type: Boolean, default: true
  field :desc,    type: String

  mount_uploader :img, LogoImageUploader

  has_and_belongs_to_many :users,     inverse_of: :liked_collections
  has_and_belongs_to_many :products,  inverse_of: :collections

  belongs_to :user, inverse_of: :oCollections

  validates :name,    presence: true, length: {maximum: Rails.configuration.max_short_text_length}
  validates :public,  presence: true
  validates :user,    presence: true
  validates :desc,    length: {maximum: (Rails.configuration.max_medium_text_length * 1.25).round}

  scope :is_public, -> { where(:public => true) }

  index({user: 1},  {unique: false,   name: :idx_collection_user})
  
end
