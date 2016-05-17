class Product
  include MongoidBase

  strip_attributes

  field :name,        type: String,   localize: true
  field :brand,       type: String,   localize: true
  field :cover,       type: String # deprecated ?
  field :desc,        type: String,   localize: true
  field :tags,        type: Array,    default: Array.new(Rails.configuration.max_num_tags)
  field :status,      type: Boolean,  default: true
  field :data,        type: String,   localize: true

  embeds_many :options,   inverse_of: :product,   cascade_callbacks: true,  class_name: 'VariantOption'
  embeds_many :skus,      inverse_of: :product,   cascade_callbacks: true

  has_and_belongs_to_many :collections,   inverse_of: :products
  has_and_belongs_to_many :categories,    inverse_of: :products

  has_many :order_items,  inverse_of: :product

  belongs_to :shop,           inverse_of: :products
  belongs_to :duty_category,  inverse_of: :products,  counter_cache: true

  accepts_nested_attributes_for :skus
  accepts_nested_attributes_for :options

  mount_uploader :cover,   ProductImageUploader # deprecated ?

  scope :without_detail, -> { only(:_id, :name, :brand, :shop_id, :cover) }
  
  validates :name,        presence: true,   length: {maximum: (Rails.configuration.max_short_text_length * 1.25).round}
  validates :brand ,      presence: true,   length: {maximum: (Rails.configuration.max_short_text_length * 1.25).round}
  validates :shop,        presence: true
  validates :status,      presence: true

  validates :desc,        length: { maximum: (Rails.configuration.max_long_text_length * 1.25).round}
  validates :tags,        length: { maximum: Rails.configuration.max_num_tags }

  scope :has_tag,         ->(value) { where( :tags => value ) }
  scope :is_active,       ->        { where( :status => true ) }
  scope :has_sku,         ->()      { where( "skus.0" => { "$exists" => true } ) }
  scope :buyable,         ->        { self.is_active.has_sku }

  index({name: 1},          {unique: false, name: :idx_product_name})
  index({brand: 1},         {unique: false, name: :idx_product_brand})
  index({shop: 1},          {unique: false, name: :idx_product_shop})
  index({tags: 1},          {unique: false, name: :idx_product_tags,        sparse: true})
  index({users: 1},         {unique: false, name: :idx_product_users,       sparse: true})
  index({collections: 1},   {unique: false, name: :idx_product_collections, sparse: true})
  index({categories: 1},    {unique: false, name: :idx_product_categories,  sparse: true})
end