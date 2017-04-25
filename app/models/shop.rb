require 'iso4217/currency_mongoid'

class Shop
  include MongoidBase

  Numeric.include CoreExtensions::Numeric::CurrencyLibrary

  strip_attributes

  field :approved,        type: Time
  field :name,            type: String
  field :shopname,        type: String,     localize: true
  field :desc,            type: String,     localize: true
  field :logo,            type: String
  field :banner,          type: String
  field :philosophy,      type: String,     localize: true
  field :stories,         type: String,     localize: true
  field :tax_number,      type: String
  field :ustid,           type: String
  field :eroi,            type: String
  field :sms,             type: Boolean,    default: false
  field :sms_mobile,      type: String
  field :min_total,       type: BigDecimal, default: 0
  field :status,          type: Boolean,    default: true
  field :founding_year,   type: String
  field :uniqueness,      type: String,     localize: true
  field :german_essence,  type: String,     localize: true
  field :sales_channels,  type: Array,      default: []
  field :register,        type: String
  field :website,         type: String
  field :agb,             type: Boolean
  field :hermes_pickup,   type: Boolean,    default: false
  field :wirecard_status, type: Symbol,     default: :unactive

  field :position, type: Integer, default: 0

  field :seal0,           type: String
  field :seal1,           type: String
  field :seal2,           type: String
  field :seal3,           type: String
  field :seal4,           type: String
  field :seal5,           type: String
  field :seal6,           type: String
  field :seal7,           type: String

  field :currency,        type: ISO4217::Currency,  default: 'EUR'

  field :fname,           type: String
  field :lname,           type: String
  field :mobile,          type: String
  field :tel,             type: String
  field :mail,            type: String
  field :function,        type: String

  field :merchant_id,     type: String
  field :bg_merchant_id,  type: String
  field :highlight,       type: Boolean, default: false

  mount_uploader :logo,   LogoUploader
  mount_uploader :banner, CoverUploader

  mount_uploader :seal0,   ProductUploader
  mount_uploader :seal1,   ProductUploader
  mount_uploader :seal2,   ProductUploader
  mount_uploader :seal3,   ProductUploader
  mount_uploader :seal4,   ProductUploader
  mount_uploader :seal5,   ProductUploader
  mount_uploader :seal6,   ProductUploader
  mount_uploader :seal7,   ProductUploader

  embeds_many :addresses,   inverse_of: :shop

  has_many  :products,        inverse_of: :shop,  dependent: :restrict
  has_many  :orders,          inverse_of: :shop,  dependent: :restrict
  has_many  :coupons,         inverse_of: :shop,  dependent: :restrict
  has_many  :payment_gateways,  inverse_of: :shop,  dependent: :restrict
  has_many  :package_sets, inverse_of: :shop, dependent: :restrict

  belongs_to :shopkeeper,   class_name: 'User',  inverse_of: :shop

  validates :name,          presence: true,   length: {maximum: (Rails.configuration.gitb[:max_tiny_text_length] * 1.25).round}
  validates :sms,           presence: true
  validates :sms_mobile,    presence: true,   :if => lambda { self.sms }, length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}
  validates :status,        presence: true
  validates :min_total,     presence: true,   numericality: { :greater_than_or_equal_to => 0 }
  validates :shopkeeper,    presence: true
  validates :currency,      presence: true
  validates :founding_year, presence: true,   length: {maximum: 4}
  validates :desc,          presence: true,   length: {maximum: (Rails.configuration.gitb[:max_medium_text_length] * 1.25).round}
  validates :philosophy,    presence: true,   length: {maximum: (Rails.configuration.gitb[:max_long_text_length] * 1.25).round}
  validates :ustid,         presence: true,   length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]},   :if => lambda { self.agb }

  validates :wirecard_status, inclusion: {:in => Rails.application.config.wirecard[:merchants][:status].map(&:to_sym)}

  validates :agb,           inclusion: {in: [true]},    :if => lambda { self.agb.present? }

  validates :register,        length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}
  validates :stories,         length: {maximum: (Rails.configuration.gitb[:max_long_text_length] * 1.25).round}
  validates :website,         length: {maximum: (Rails.configuration.gitb[:max_short_text_length] * 1.25).round}
  validates :eroi,            length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}
  validates :uniqueness,      length: {maximum: (Rails.configuration.gitb[:max_medium_text_length] * 1.25).round}
  validates :german_essence,  length: {maximum: (Rails.configuration.gitb[:max_medium_text_length] * 1.25).round}
  validates :shopname,        length: {maximum: Rails.configuration.gitb[:max_short_text_length]}

  # This seems to be systematically empty, should we keep the fields ? - Laurent on 02/06/2016 (i changed to presence: false)
  validates :fname,         presence: false,   length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}
  validates :lname,         presence: false,   length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}
  validates :tel,           presence: false,   length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}
  validates :mail,          presence: false,   length: {maximum: Rails.configuration.gitb[:max_short_text_length]}

  validates :mobile,        length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}
  validates :function,      length: {maximum: Rails.configuration.gitb[:max_tiny_text_length]}

  scope :is_active,       ->    { where( :status => true ).where( :approved.ne => nil ) }
  scope :has_address, -> { where({ :addresses => { :$not => { :$size => 0 } } }) }

  scope :is_bg_merchant,  ->    { where(:bg_merchant_id.ne => nil) }
  scope :can_buy,         ->    { is_active.is_bg_merchant.has_address }
  scope :highlighted,     ->    { where(highlight: true) }

  before_save :ensure_shopkeeper
  before_save :clean_sms_mobile,  :unless => lambda { self.sms }
  before_save :force_wirecard_status
  before_save :force_merchant_id

  index({shopkeeper: 1},    {unique: true,   name: :idx_shop_shopkeeper})
  index({merchant_id: 1},   {unique: false,  name: :idx_shop_merchant_id})

  def force_merchant_id
    if self.merchant_id.nil?
      self.merchant_id = (self.c_at ? self.c_at.strftime('%y%m%d') : Date.today.strftime('%y%m%d')) + self.name.delete("\s")[0,3].upcase
    end
  end

  def billing_address
    addresses.is_billing.first
  end

  def sender_address
    addresses.is_shipping.first
  end

  def country
    sender_address = addresses.find_sender
    sender_address ? sender_address.country : nil
  end

  def country_of_dispatcher
    sender_address.country
  end

  def categories
    all_categories = Category.order_by(position: :asc).all.map { |c| [c.id, c]}.to_h
    products.inject(Set.new) {|cs, p| cs = cs + p.category_ids }.map { |c| all_categories[c]}
  end

  def payment_method?(payment_method)
    self.payment_gateways.map(&:payment_method).include? payment_method
  end

  def discount?
    self.products.discount_products
  end

  def can_buy?
    active? && bg_merchant_id != nil && addresses.is_shipping.count > 0
  end

  def active?
    status == true && approved != nil
  end

  def can_change_to_billing?
    true
  end

  def can_change_to_sender?
    true
  end

  def can_change_to_both?
    true
  end

  private

  def force_wirecard_status
    self.wirecard_status = :unactive if self.wirecard_status.nil?
  end

  def ensure_shopkeeper
    shopkeeper.role == :shopkeeper
  end

  def clean_sms_mobile
    self.sms_mobile = nil
  end

  def self.with_can_buy_products
    self.in(id: Product.can_buy.map {|p| p.shop_id } ).all
  end

end
