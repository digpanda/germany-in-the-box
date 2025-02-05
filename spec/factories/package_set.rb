 FactoryGirl.define do
   factory :package_set do

     name        { Faker::Name.name }
     shop        { FactoryGirl.create(:shop, :with_payment_gateways) }
     desc        { Faker::Lorem.paragraph }
     cover       { Rack::Test::UploadedFile.new(File.join(Rails.root, 'public', 'samples', 'images', 'banner', '850x400.png')) }
     category    { Category.offset(rand(Category.count)).first || FactoryGirl.create(:category) }
     shipping_cost { BigDecimal.new(rand(1..10)) }

     # NOTE : different data than Product
     # to make sure this area is tested
     # and not mixed up
     default_referrer_rate 5.0
     junior_referrer_rate 10.0
     senior_referrer_rate 15.0

     after(:create) do |package_set|
       FactoryGirl.create_list(:package_sku, 5, package_set: package_set)
     end

     trait :with_500_euro_total do
       after(:create) do |package_set|
         package_set.package_skus.delete_all
         FactoryGirl.create_list(:package_sku, 5, package_set: package_set, quantity: 1, casual_price: 70, taxes_per_unit: 20)
       end
     end

   end
 end
