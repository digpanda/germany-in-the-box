class Address
  include MongoidBase

  CHINESE_CHARACTERS = /[\u4e00-\u9fa5]+/
  CHINESE_ID = /(\d{6})(19|20)(\d{2})(1[0-2]|0[1-9])(0[1-9]|[1-2][0-9]|3[0-1])(\d{3})(\d|X|x)/

  strip_attributes

  field :full_address

  field :country,       type: Symbol, default: :china # [:china, :europe]
  field :type,          type: Symbol, default: :both
  field :company,       type: String

  field :fname,         type: String
  field :lname,         type: String
  field :pid,           type: String
  field :email,         type: String
  field :mobile,        type: String

  embedded_in :shop, inverse_of: :addresses
  embedded_in :user, inverse_of: :addresses

  embedded_in :order, inverse_of: :billing_address
  embedded_in :order, inverse_of: :shipping_address

  scope :is_billing,          ->  { any_of({ type: :billing }, { type: :both }) }
  scope :is_shipping,         ->  { any_of({ type: :shipping },  { type: :both }) }
  scope :is_any,              ->  { any_of({ type: :shipping },  { type: :billing }, { type: :both }) }

  scope :is_only_billing,     ->  { any_of(type: :billing) }
  scope :is_only_shipping,    ->  { any_of(type: :shipping) }
  scope :is_only_both,        ->  { any_of(type: :both) }

  validates :mobile, presence: true, if: -> { user&.customer? }
  validates :pid, presence: true, if: -> { user&.customer? && self.country == :china }
  validates :fname, presence: true
  validates :lname, presence: true


  validates :country, presence: true
  validates :company, presence: true, if: -> { shop.present? }
  validates :type, presence: true , inclusion: { in: [:billing, :shipping, :both] }
  validates :country, presence: true , inclusion: { in: [:china, :europe] }

  before_save :ensure_valid_mobile

  def ensure_valid_mobile
    if mobile
      mobile.gsub!(/[[:space:]]/, '')
    end
  end

end
