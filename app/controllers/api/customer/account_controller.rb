class Api::Customer::AccountController < Api::ApplicationController
  attr_reader :user

  authorize_resource class: false
  before_action :set_user

  def update
    if update_user
      render json: { success: true, message: I18n.t('notice.account_updated'), user: UserSerializer.new(user) }
    else
      render json: { success: false, error: user.errors.full_messages.join(',') }
    end
  end

  private

    def set_user
      @user = current_user
    end

    def user_params
      params.require(:user).permit(:username, :email, :fname, :lname, :birth, :gender, :resellers_platform_at)
    end

    def update_user
      ensure_birth
      ensure_resellers_platform_at
      user.update(user_params)
    end

    def ensure_birth
      if params[:user][:birth]
        birth = params[:user][:birth]
        params[:user][:birth] = "#{birth[:year]}-#{birth[:month]}-#{birth[:day]}"
      end
    end

    # if it's a boolean saying true then we replace with the current date
    # only if the user doesn't have a date already
    def ensure_resellers_platform_at
      if !user.resellers_platform_at && params[:user][:resellers_platform_at] == true
        params[:user][:resellers_platform_at] = Time.now
      else
        params[:user][:resellers_platform_at] = user.resellers_platform_at
      end
    end
end
