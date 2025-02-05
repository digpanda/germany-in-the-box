require 'uri'
require 'net/http'

class Guest::ShopApplicationsController < ApplicationController
  DEFAULT_PAYMENT_GATEWAYS = [:alipay, :wechatpay].freeze

  attr_reader :shop_application

  before_action :force_german
  layout :default_layout

  def new
    @shop_application = ShopApplication.new
  end

  def create
    @shop_application = ShopApplication.new(shop_application_params)
    return throw_model_error(shop_application, :new) unless shop_application.save

    user = shopkeeper_from_shop_application!(shop_application)

    if user.errors.any? # rollback
      shop_application.delete
      return throw_model_error(user, :new)
    end

    shop = Shop.new(shop_params)
    shop.shopname = shop.name # marketing name
    shop.shopkeeper = user

    unless shop.save
      shop_application.delete
      user.delete
      return throw_model_error(shop, :new)
    end

    ensure_payment_gateways!(shop)
    flash[:success] = I18n.t('shop_application.application_submitted')
    redirect_to navigation.back(1)
  end

  private

    def ensure_payment_gateways!(shop)
      DEFAULT_PAYMENT_GATEWAYS.each do |payment_method|
        payment_gateway = PaymentGateway.where(shop_id: shop.id, payment_method: payment_method).first || PaymentGateway.new
        payment_gateway.shop_id = shop.id
        payment_gateway.provider = payment_method
        payment_gateway.payment_method = payment_method
        payment_gateway.save
      end
    end

    def shopkeeper_from_shop_application!(shop_application)
      User.create(
        nickname: shop_application.email,
        email: shop_application.email,
        mobile: shop_application.mobile,
        password: shop_application.code[0, 8],
        password_confirmation: shop_application.code[0, 8],
        role: :shopkeeper
      )
    end

    def force_german
      session[:locale] = :de
      I18n.locale = session[:locale]
    end

    def shop_params
      shop_application_params.except(:email, :mobile, :tel, :function)
    end

    def shop_application_params
      params.require(:shop_application).permit(:email, :name, :shopname, :desc, :philosophy, :stories, :german_essence, :uniqueness, :founding_year, :register, :website, :fname, :lname, :mobile, :tel, :mail, :function)
    end
end
