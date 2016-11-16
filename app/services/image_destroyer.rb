# remove images dynamically
class ImageDestroyer < BaseService

  # TODO : this is not a good way to tackle the problem
  # the structure of the model itself should be changed
  # this is pathetic to have such fields in the database.
  # we are not a bunch of amateurs.
  # - Laurent
  SHOP_IMAGE_FIELDS = [:logo, :banner, :seal0, :seal1, :seal2, :seal3, :seal4, :seal5, :seal6, :seal7]
  SKU_IMAGE_FIELDS = [:img0, :img1, :img2, :img3]

  attr_reader :model, :authorized_fields

  def initialize(model)
    @model = model
  end

  def perform(image_field)
    image_field = image_field.to_sym
    if valid_model_image?(image_field)
      remove!(image_field)
    else
      false
    end
  end

  private

  def authorized_fields
    @authorized_fields ||= begin
      case model
      when Shop
        SHOP_IMAGE_FIELDS
      when Sku
        SKU_IMAGE_FIELDS
      else
        []
      end
    end
  end

  def remove!(image_field)
    model.send("remove_#{image_field}=", true)
    model.save
  end

  def valid_model_image?(image_field)
    model.respond_to?(image_field) && authorized_fields.include?(image_field)
  end

end
