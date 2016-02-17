class OrderItem
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :quantity,  type: Integer,    default: 1
  field :weight,    type: Float,      default: 0
  field :price,     type: BigDecimal, default: 0

  belongs_to :product,  :inverse_of => :order_items
  belongs_to :order,    :inverse_of => :order_items,  touch: true

  validates :quantity,  presence: true, :numericality => { :greater_than_or_equal_to => 1 }
  validates :weight,    presence: true, :numericality => { :greater_than_or_equal_to => 0 }
  validates :price,     presence: true, :numericality => { :greater_than_or_equal_to => 0 }
  validates :product,   presence: true
  validates :order,     presence: true
end