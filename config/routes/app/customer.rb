# Customer related
namespace :customer do

  resource :referrer, controller: 'referrer' do
    get :group_insight
    get :children_insight
    get :provision
    get :provision_rates
    get :coupons
    get :qrcode
    post :claim
    get :agb

    resource :customization, controller: 'referrer/customization' do
    end

    resources :links, controller: 'referrer/links' do
      get :share
    end
  end

  resource :cart, controller: 'cart' do
  end

  namespace :checkout do
    namespace :callback do

      resource :alipay, controller: 'alipay' do
      end

      resource :wechatpay, controller: 'wechatpay' do
        get :fail
        get :cancel
      end

    end
  end

  resource :checkout, controller: 'checkout' do
    get :payment_method
    get '/gateways/:payment_method', to: 'checkout#gateway', as: 'gateway'
    # get :gateway
  end

  resource :account, controller: 'account' do
    get :menu
    get :missing_info
  end

  resource :identity, controller: 'identity' do
  end

  resources :addresses do
  end

  resources :orders  do
    patch :continue

    resource :customer, controller: 'orders/customer' do
    end

    resources :addresses, controller: 'orders/addresses' do
    end

    resource :coupons, controller: 'orders/coupons' do
    end
  end

  resources :favorites  do
  end

end
