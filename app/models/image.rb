class Image
  include MongoidBase
  include Concerns::Imageable

  field :file, type: String
  mount_uploader :file, ImageUploader

  belongs_to :image, polymorphic: true

  def thumb
    image_url(:file, :thumb)
  end

end
