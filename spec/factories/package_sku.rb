FactoryGirl.define do
  factory :package_sku do

    quantity 2
    price { BigDecimal.new(rand(1..10)) }
    taxes_per_unit { BigDecimal.new(rand(1..10)) }

    before(:create) do |package_sku|

      shop = package_sku.package_set.shop
      product = shop.products.first
      sku = product.skus.first

      package_sku.product = product
      package_sku.sku_id = sku.id

    end

  end
end
