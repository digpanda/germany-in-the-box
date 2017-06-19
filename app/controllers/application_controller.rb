require 'base64_to_upload'

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

  before_action :origin_solver, :landing_solver, :silent_login, :get_cart_orders

  def silent_login
    if params[:code]
      SlackDispatcher.new("SILENT LOGIN UNDER PROGRESS")
      if wechat_auth.success?
        sign_out
        user = wechat_auth.data[:customer]
        sign_in(:user, user)
        SlackDispatcher.new.silent_login_attempt("[Wechat] Customer automatically logged-in (`#{current_user&.id}`)")
        redirect_to SigninHandler.new(request, navigation, current_user, cart_manager).solve!(refresh: true)
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

  def setting
    @setting ||= Setting.instance
  end

  def custom_sublayout
    "layouts/#{identity_solver.section}/submenu"
  end

  def default_layout
    "application"
  end

  def wechat_auth
    @wechat_auth ||= WechatAuth.new(params[:code], params[:token], params[:force_referrer]).resolve!
  end

  def freeze_header
    @freeze_header = true
  end

  def origin_solver
    return session[:origin] if session[:origin]
    SlackDispatcher.new.message("ORIGIN SOLVER SOLVED.")
    if chinese_domain? || wechat_browser?
      session[:origin] = :wechat
    else
      session[:origin] = :browser
    end
  end

  def landing_solver
    SlackDispatcher.new.message("LANDING SOLVER SOLVED.")
    @landing_solver ||= LandingSolver.new(request).setup!
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

  def get_cart_orders
    current_user&.cart&.orders&.each do |order|
      cart_manager.store(order)
    end
  end

end
