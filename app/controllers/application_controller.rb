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

  before_action :assign_introducer, :assign_label, :assign_group, :assign_referrer

  before_action :force_wechat_login
  before_action :solve_silent_login, :solve_origin, :solve_landing

  before_action :ensure_price_origin, :ensure_customization

  # this is used to work with the models
  # we should never share contextual data with the model
  # but for the sku / package sets pricing system the best was to actually throw a thread variable
  # rather than changing the whole system
  def ensure_price_origin
    if current_user&.referrer
      if current_user.group == :junior
        Thread.current[:price_origin] = :junior_reseller_price
      elsif current_user.group == :senior
        Thread.current[:price_origin] = :senior_reseller_price
      else
        Thread.current[:price_origin] = :default_reseller_price
      end
    else
      Thread.current[:price_origin] = :casual_price
    end
  end

  # if a user comes from wechat browser and is not logged-in yet
  # we force-login him to the correct domain
  def force_wechat_login
    return unless Rails.env.production? # this should work solely in production
    return if current_user
    return if params[:code]
    return unless identity_solver.wechat_browser?
    redirect_to WechatUrlAdjuster.new(identity_solver.wechat_url).adjusted_url
  end

  # we try to silent login the users
  # with the code in parameters (typically wechat related)
  def solve_silent_login
    return unless params[:code]
    return unless wechat_silent_login.connect!
    redirect_to wechat_silent_login.redirect(refresh: true)
  end

  def wechat_silent_login
    @wechat_silent_login ||= WechatSilentLogin.new(request: request, navigation: navigation, cart_manager: cart_manager, code: params[:code])
  end

  def activate_weixin_js_config
    @weixin_js_config ||= begin
      ticket = WechatTicket.new(cache_scope: request.host).resolve
      return false unless ticket.success?
      js_config = WechatApi::JsConfig.new(request: request, ticket: ticket.data[:ticket]).resolve
      return false unless js_config.success?
      js_config.data
    end
  end

  # if there is a URL containing a code
  # we try to bind automatically the user to the introducer
  def assign_introducer
    session[:introducer] = params[:introducer] if params[:introducer]
  end

  # if there is a URL containing a code
  # we try to store it before sign-in
  def assign_label
    session[:label] = params[:label] if params[:label]
  end

  # if there is a URL containing a code
  # we try to store it before sign-in
  def assign_group
    session[:group] = params[:group] if params[:group]
  end

  # if there is a URL containing a code
  # we try to store it before sign-in
  def assign_referrer
    if params[:reference_id]
      session[:reference_id] = params[:reference_id]
    end
  end

  def current_page
    if params[:page]
      params[:page].to_i
    else
      1
    end
  end

  def ensure_customization
    @customization = current_user&.parent_referrer&.customization
  end

  def slack
    @slack ||= SlackDispatcher.new
  end

  def navigation
    @navigation ||= NavigationHistory.new(request, session)
  end

  def cart_manager
    @cart_manager ||= CartManager.new(request, current_user)
  end

  def identity_solver
    @identity_solver ||= IdentitySolver.new(request, current_user)
  end

  def setting
    @setting ||= Setting.instance
  end

  def custom_sublayout
    "layouts/#{identity_solver.section}/submenu"
  end

  def default_layout
    'application'
  end

  def minimal_layout
    @minimal_layout = true
  end

  def solve_origin
    identity_solver.origin_setup!
  end

  def solve_landing
    identity_solver.landing_solver.setup!
  end

  def restrict_to(section)
    unless identity_solver.section == section # :customer, :shopkeeper, :admin
      navigation.reset! # we reset to avoid infinite loop
      throw_unauthorized_page
    end
  end

  def valid_group_leader?
    unless current_user&.referrer&.group_leader
      flash[:error] = I18n.t('general.not_allowed_section')
      redirect_to root_path
      false
    end
  end

  def valid_referrer?
    unless current_user&.referrer?
      flash[:error] = I18n.t('general.not_allowed_section')
      redirect_to root_path
      false
    end
  end
end
