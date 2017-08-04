class Admin::ReferrersController < ApplicationController
  attr_accessor :referrer, :referrers

  before_action :set_referrer, :except => [:index, :new]

  before_action :breadcrumb_admin_referrers, :except => [:index]
  before_action :breadcrumb_admin_referrer, :except => [:index]
  before_action :breadcrumb_admin_referrer_provisions, only: [:provisions]
  before_action :breadcrumb_admin_referrer_coupon, only: [:coupon]

  authorize_resource class: false
  layout :custom_sublayout

  def index
    @referrers = Referrer.full_text_search(params[:query], match: :all, allow_empty_search: true).all
  end

  def show
  end

  # NOTE : i'm not sure it's still in use
  # Laurent, 02/08/2017
  def new
    @referrer_group = ReferrerGroup.create
    @url = "https://open.weixin.qq.com/connect/oauth2/authorize?" +
        "appid=#{Rails.application.config.wechat[:username_mobile]}&" +
        "redirect_uri=http%3A%2F%2Fgermanyinbox.com/connect/auth/referrer?" +
        "token=#{@referrer_group.token}" +
        "&response_type=code&scope=snsapi_userinfo&state=STATE#wechat_redirect"
  end

  def update
    if referrer.update(referrer_params)
      flash[:success] = "The referrer was updated."
    else
      flash[:error] = "The referrer was not updated (#{referrer.errors.full_messages.join(', ')})"
    end
    redirect_to navigation.back(1)
  end

  def coupon
    coupon = Coupon.create_referrer_coupon(referrer)
    if coupon
      flash[:success] = "The coupon was created."
    else
      flash[:error] = "The coupon was not created (#{coupon&.errors&.full_messages&.join(', ')})"
    end
    redirect_to navigation.back(1)
  end

  private

    def set_referrer
      @referrer = Referrer.find(params[:id] || params[:referrer_id])
    end

    def referrer_params
      params.require(:referrer).permit!
    end
end
