# Admin related
require 'sidekiq/web'

namespace :admin do

  resources :shipping_rates do
  end

  resources :categories do
    delete :destroy_image
  end

  resources :coupons do
    patch :cancel
    patch :approve
  end

  resources :payment_gateways do
  end

  resources :notes do
  end

  resources :shops do
    get :emails, on: :collection
    patch :approve
    post :force_login
    patch :disapprove
    delete :destroy_image

    resources :package_sets, :controller => 'shops/package_sets' do
      delete :destroy_image
    end

    resources :products, :controller => 'shops/products' do
      patch :regular
      patch :highlight
      patch :approve
      patch :disapprove

      resources :variants, :controller => 'shops/products/variants' do
        delete '/option/:option_id', action: :destroy_option, as: :destroy_option
      end

      resources :skus, :controller => 'shops/products/skus' do
        delete :destroy_image
        patch :clone
      end

    end


  end

  resources :shop_applications do
  end

  resources :orders do
    patch :reset_border_guru_order
  end

  resource :search, :controller => 'search' do
  end

  resource :account, :controller => 'account' do
  end

  resources :referrers do
    post :coupon
  end

  resources :users do
    get :emails, on: :collection
  end

  resources :order_payments do
    post :refund
    post :check
    patch :transaction_id
  end

  resources :settings do
    delete :destroy_image
  end

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

end
