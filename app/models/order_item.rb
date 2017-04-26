class OrderItem
  include MongoidBase
  include Locked

  SKU_DELEGATE_EXCEPTION = [:quantity]
  MAX_DESCRIPTION_CHARACTERS = 200

  field :quantity, type: Integer,    default: 1

  field :taxes_per_unit, type: Float
  field :shipping_per_unit, type: Float
  field :price_per_unit, type: Float

  field :referrer_rate, type: Float, default: 0.0

  before_save :ensure_price_per_unit, :ensure_taxes_per_unit, :ensure_shipping_per_unit

  def ensure_price_per_unit
    unless price_per_unit
      self.price_per_unit = sku.price_per_unit
    end
  end

  def ensure_taxes_per_unit
    unless taxes_per_unit
      self.taxes_per_unit = sku.taxes_per_unit
    end
  end

  def ensure_shipping_per_unit
    unless shipping_per_unit
      self.shipping_per_unit = sku.shipping_per_unit
    end
  end

  belongs_to :product
  belongs_to :order, :counter_cache => true
  belongs_to :package_set

  # if we use the model somewhere else than the product
  # like in `order_item` we need to trace the original sku
  # this is essential to transmit informations and see clear
  # we use this data to avoid getting lost with the ids
  # NOTE : maybe make a small library to manage this kind of things in a DRY way
  belongs_to :sku_origin, class_name: 'Sku', foreign_key: :sku_origin_id
  def sku_origin
    product.skus.find(sku_origin_id)
  end

  embeds_one :sku

  validates :quantity,      presence: true, :numericality => { :greater_than_or_equal_to => 1 }
  validates :product,       presence: true
  validates :order,         presence: true

  index({order: 1},  {unique: false, name: :idx_order_item_order})

  scope :with_sku, -> (sku) { self.where(:sku_origin_id => sku.id) }

  # right now we exclusively have delegated methods from the sku
  # if the method is missing we get it from the sku
  # directly when possible
  def method_missing(method, *params, &block)
    return if SKU_DELEGATE_EXCEPTION.include?(method)
    if sku.respond_to?(method)
      sku.send(method, *params, &block)
    end
  end

  def selected_options(locale=nil)
    product.options.map do |option|
      option.suboptions.map do |suboption|
        if option_ids.include? suboption.id.to_s
          if locale.nil?
          suboption.name
          else
          suboption.name_translations[locale]
          end
        end
      end
    end.flatten.compact
  end

  def clean_desc
    "#{product.clean_name} #{product.decorate.clean_desc(MAX_DESCRIPTION_CHARACTERS)}"
  end

  # this method should be used in only a few cases
  # we originally created it to call the BorderGuru API with the correct prices
  # considering the coupon system.
  # using it as end_price would make a double discount which would be false. please avoid this.
  # NOTE : we want to get the `price` per unit not the `total_price` because of BorderGuru API
  def price_with_coupon_applied
    (price_per_unit * order.total_discount_percent).round(2)
  end

  def total_price
    # NOTE : this has to be removed at some point
    ensure_price_per_unit
    quantity * price_per_unit
  end

  def total_taxes
    quantity * taxes_per_unit
  end

  def total_price_with_taxes
    total_price + total_taxes
  end

  def price_with_taxes
    price_per_unit + taxes_per_unit
  end

  def volume
    sku.volume * quantity
  end

end
