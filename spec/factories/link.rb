FactoryGirl.define do

  factory :link, class: Link do

    title { Faker::Name.name }
    raw_url 'http://test.com/link-goes-somewhere'
    position 0

  end

end
