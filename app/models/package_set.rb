class PackageSet
  include MongoidBase

  field :name
  field :desc
  field :cover,       type: String

  mount_uploader :cover, CoverUploader

  belongs_to :shop, inverse_of: :package_sets
  embeds_many :package_skus, inverse_of: :package_set, cascade_callbacks: true
  has_many :order_items

  accepts_nested_attributes_for :package_skus, :reject_if => :reject_package_skus

  def reject_package_skus(attributed)
    attributed['product'].blank? && attributed['sku_id'].blank?
  end

  validates_presence_of :name
  validates_presence_of :desc
  validates_presence_of :cover
  validates_with UniquePackageSkuValidator

  def casual_price
    self.package_skus.reduce(0) do |acc, package_sku|
      acc + package_sku.sku.price_with_taxes
    end
  end

  def price
    self.package_skus.reduce(0) do |acc, package_sku|
      acc + package_sku.total_price
    end
  end

  def previous
    self.class.where(:_id.lt => self._id).order_by([[:_id, :desc]]).limit(1).first
  end

  def next
    self.class.where(:_id.gt => self._id).order_by([[:_id, :asc]]).limit(1).first
  end

end
