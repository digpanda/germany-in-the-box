if Rails.env.production?
  concerns :shared_errors
end

# We should improve this by putting it into a home_controller with index
root to: 'pages#home'

namespace :wirecard do
  namespace :webhook do 
    post 'merchant_status_change', action: :merchant_status_change, as: :merchant_status_change
  end
end


# We should improve this by creating a real controller
get '/set_session_locale/:locale', to: 'application#set_session_locale', as: 'set_session_locale'

captcha_route
mount ChinaCity::Engine => '/china_city'
devise_for :users, :controllers => { registrations: "registrations", sessions: "sessions", omniauth_callbacks: "omniauth_callbacks"}

devise_scope :user do
  concerns :shared_user
end

resource :page do
  concerns :shared_page
end

namespace :admin do
  resources :payments do
  end
  resource :settings, only: [:show, :update] do
  end
end

namespace :shopkeeper do
  resources :orders do
    patch :process
    patch :shipped
  end
  resources :payments do
  end
  resource :wirecard do
    get :apply, :on => :member
  end
end

resources :addresses, except: [:new, :edit] do
end

resources :products, except: [:index, :new] do
  concerns :shared_products
end

resources :users do
  concerns :shared_users
end

resources :shops, except: [:new, :edit, :create] do
  concerns :shared_shops
end

resources :shop_applications, except: [:edit, :update] do
  concerns :shared_shop_applications
end

# Guest related
namespace :guest do

  resources :order_items  do
    concerns :shared_guest_order_items
  end

  resources :products  do
    concerns :shared_guest_products
  end

end

# Customer related
namespace :customer do

  resources :favorites  do
    concerns :shared_customer_favorites
  end

end

# Shared related
namespace :shared do

  resources :notifications do
    concerns :shared_shared_notifications
  end

end
resources :orders, only: [:destroy, :show] do
  concerns :shared_orders

  match :download_label,  via: [:get],  action: :download_label,  as: :download_label,  :on => :member
end

resources :categories, only: [:show, :index] do
  concerns :shared_categories
end