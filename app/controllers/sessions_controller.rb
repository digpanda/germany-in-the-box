require 'open-uri'

class SessionsController < Devise::SessionsController

  skip_before_filter :verify_signed_out_user
  before_action :authenticate_user!, except: [:new, :create, :destroy]

  def new
    session[:login_advice_counter] = 1
  end

  def failure
    warden.custom_failure!
    redirect(:back) and return
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  def destroy
    if current_user.nil?
      redirect_to root_url
      return
    end
    reset_session
    redirect_to root_url
  end

  def cancel_login
    session.delete(:login_advice_counter)
  end

end
