require 'base64_to_upload'
require 'border_guru'

class ApplicationController < ActionController::Base

  include HttpAcceptLanguage::AutoLocale

  include Application::Exceptions
  include Application::Ability
  include Application::Language
  include Application::Devise
  include Application::Breadcrumb
  include Application::Categories

  include Mobvious::Rails::Controller

  helper_method :navigation, :cart_manager, :identity_solver

  before_action :silent_login, :origin_solver

  def silent_login
    if params[:code]
      SlackDispatcher.new.silent_login_attempt("Attempting to authorize...")
      if wechat_auth.success?
        session[:origin] = :wechat
        SlackDispatcher.new.silent_login_attempt("Success!!")
        sign_out
        sign_in(:user, wechat_auth.data[:customer])
        if current_user.cart_orders.first
          cart_manager.store(current_user.cart_orders.first)
        end
        if wechat_auth.data[:tourist_guide]
          redirect_to customer_referrer_path
          return
        end
      end
    end
  end

  def current_page
    if params[:page]
      params[:page].to_i
    else
      1
    end
  end

  def slack
    @slack ||= SlackDispatcher.new
  end

  def navigation
    @navigation ||= NavigationHistory.new(request, session)
  end

  def cart_manager
    @cart_manager ||= CartManager.new(session, current_user)
  end

  def identity_solver
    @identity_solver ||= IdentitySolver.new(request, session, current_user)
  end

  def settings
    @setting ||= Setting.instance
  end

  def custom_sublayout
    "layouts/#{identity_solver.section}/submenu"
  end

  def default_layout
    "application"
  end

  def wechat_auth
    @wechat_auth ||= WechatAuth.new(params[:code], params[:token]).resolve!
  end

  def freeze_header
    @freeze_header = true
  end

  def origin_solver
    return session[:origin] if session[:origin]
    if chinese_domain? || wechat_browser?
      session[:origin] = :wechat
    else
      session[:origin] = :browser
    end
  end

  def wechat_browser?
    request.user_agent&.include? "MicroMessenger"
  end

  def chinese_domain?
    request.url&.include? "germanyinbox.com"
  end

  def restrict_to(section)
    unless identity_solver.section == section # :customer, :shopkeeper, :admin
      navigation.reset! # we reset to avoid infinite loop
      throw_unauthorized_page
    end
  end

end
