class Shop
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  include DocLocaleName

  strip_attributes

  field :name,            type: String
  field :desc,            type: String
  field :logo,            type: String
  field :banner,          type: String
  field :philosophy,      type: String
  field :stories,         type: String
  field :ustid,           type: String
  field :eroi,            type: String
  field :sms,             type: Boolean,    default: false
  field :sms_mobile,      type: String
  field :min_total,       type: BigDecimal, default: 0
  field :currency,        type: String,     default: '€'
  field :status,          type: Boolean,    default: true
  field :founding_year,   type: String
  field :uniqueness,      type: String
  field :german_essence,  type: String
  field :target_groups,   type: Array,      default: []
  field :sales_channels,  type: Array,      default: []
  field :register,        type: String
  field :website,         type: String

  field :name_locales,    type: Hash

  mount_uploader :logo,   AttachmentUploader
  mount_uploader :banner, AttachmentUploader

  has_one   :bank_account,    inverse_of: :shop,  dependent: :restrict
  has_one   :address,         inverse_of: :shop,  dependent: :restrict

  has_many  :products,  inverse_of: :shop,  dependent: :restrict

  belongs_to :shopkeeper,   class_name: 'User',  inverse_of: :shop

  validates :name,          presence: true,   length: {maximum: Rails.configuration.max_tiny_text_length}
  validates :sms,           presence: true
  validates :sms_mobile,    presence: true,   :if => lambda { self.sms }, length: {maximum: Rails.configuration.max_tiny_text_length}
  #validates :billing_address,       presence: true,   :if => lambda { self.status == :opened }
  #validates :bank_account,  presence: true,   :if => lambda { self.status == :opened }
  validates :status,        presence: true
  validates :min_total,     presence: true,   numericality: { :greater_than_or_equal_to => 0 }
  validates :shopkeeper,    presence: true
  validates :currency,      presence: true,   inclusion: {in: ['€']}
  validates :founding_year, presence: true,   length: {maximum: 4}
  validates :register,      presence: true,   length: {maximum: Rails.configuration.max_tiny_text_length}
  validates :desc,          presence: true,   length: {maximum: Rails.configuration.max_medium_text_length}
  validates :philosophy,    presence: true,   length: {maximum: Rails.configuration.max_medium_text_length}
  validates :stories,       presence: true,   length: {maximum: Rails.configuration.max_long_text_length}

  validates :website,       length: {maximum: Rails.configuration.max_short_text_length}

  validates :ustid,         length: { maximum: Rails.configuration.max_tiny_text_length, :allow_blank => true }
  validates :eroi,          length: { maximum: Rails.configuration.max_tiny_text_length, :allow_blank => true }

  scope :is_active,       ->        { where( :status => true ) }

  before_save :ensure_shopkeeper
  before_save :clean_sms_mobile, :unless => lambda { self.sms }

  private

  def ensure_shopkeeper
    shopkeeper.role == :shopkeeper
  end

  def clean_sms_mobile
    self.sms_mobile = nil
  end

end