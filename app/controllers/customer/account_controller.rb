class Customer::AccountController < ApplicationController
  attr_reader :user

  authorize_resource class: false
  before_action :set_user

  layout :custom_sublayout, except: [:missing_info]

  def edit
  end

  # NOTE : this update is used from many different points
  # within the system (e.g checkout process) be careful with this.
  def update
    if valid_password? && ensure_password && update_user
      # update email nonetheless without waiting for confirmation
      # NOTE : this was coded regarding a bug on missing informations
      # it should be optimized.
      if email_to_update?
        user.confirmed_at = nil
        user.skip_reconfirmation!
        user.email = user_params[:email]
        user.save(validate: false)
      end

      flash[:success] = I18n.t('notice.account_updated')
      sign_in(user, bypass: true)
    else
      flash[:error] = user.errors.full_messages.join(',')
    end
    redirect_to navigation.back(1)
  end

  def menu
  end

  # missing details / informations the user needs to fill in
  def missing_info
    unless current_user.missing_info?
      # NOTE : the missing info can be triggered from multiple points
      # therefore it's just better to get back to the origin url.
      # unless it's a referrer which needs to see his dashboard first
      if user.referrer?
        redirect_to customer_referrer_path
      else
        redirect_to identity_solver.origin_url
      end
    end
  end

  private

    def email_to_update?
      (user_params[:email] != user.email) && (user_params[:email].present?)
    end

    def set_user
      @user = current_user
    end

    def user_params
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :fname, :lname, :birth, :gender, :about, :website, :pic, :mobile, referrer_attributes: [:agb])
    end

    def password_needed?
      return false if user.wechat?
      return false if current_user.missing_info?
      true
    end

    def valid_password?
      return true unless password_needed?
      if user.valid_password?(params[:user][:current_password])
        true
      else
        user.errors.add(:password, 'wrong')
        false
      end
    end

    def update_user
      ensure_birth
      user.update(user_params)
    end

    def ensure_birth
      if params[:user][:birth]
        birth = params[:user][:birth]
        params[:user][:birth] = "#{birth[:year]}-#{birth[:month]}-#{birth[:day]}"
      end
    end

    def ensure_password
      unless password_needed?
        params[:user][:password] = params[:user][:password_confirmation] = params[:user][:current_password]
      end
      true
    end
end
