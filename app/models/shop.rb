
class Shop
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  strip_attributes

  field :name,    type: String
  field :desc,    type: String
  field :logo,    type: String
  field :banner,  type: String

  has_many :products, inverse_of: :shop

  mount_uploader :logo, AttachmentUploader
  mount_uploader :banner, AttachmentUploader
end