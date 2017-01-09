class OrderItem
  include MongoidBase
  include LockedParent

  SKU_DELEGATE_EXCEPTION = [:quantity]
  MAX_DESCRIPTION_CHARACTERS = 200

  field :quantity,        type: Integer,    default: 1

  # if we want to setup the taxes by ourselves
  field :manual_taxes, type: Boolean, default: false
  # this hook the sku `estimated_taxes` method by forcing a 0
  # if the taxes are manually calculated beforehand
  def estimated_taxes
    if manual_taxes
      0
    else
      sku.estimated_taxes
    end
  end

  belongs_to :product
  belongs_to :order, touch: true,  :counter_cache => true

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
    (price * order.total_discount_percent).round(2)
  end

  def total_price
    quantity * price
  end

  def volume
    sku.volume * quantity
  end

end
