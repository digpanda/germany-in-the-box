class Connect::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # skip CSRF on create.
  skip_before_filter :verify_authenticity_token
  skip_before_action :solve_silent_login # this is useful for #referrer

  # QRCode Wechat classic login system
  def wechat
    if wechat_user_solver.success?
      sign_in_user wechat_user_solver.data[:customer]
    else
      failure
    end
  end

  # QRCode Wechat tour guide registration
  # NOTE : token here means referrer token which was changed inside the system. (yeah disgusting)
  # it's only a way to group people.
  def referrer
    SlackDispatcher.new.message("THIS USER MIGHT TURN INTO A REFERRER")
    if params[:code]
      # this is taken from application controller
      SlackDispatcher.new.message("IT HAS A CODE, LETS DO IT")
      SlackDispatcher.new.message("#{wechat_api_connect_solver.error}")
      if wechat_api_connect_solver.success?
        SlackDispatcher.new.message("WECHAT API PASSED")
        user = wechat_api_connect_solver.data[:customer]

        # we turn him into a real referrer
        ReferrerMaker.new(user).convert!(group_token: params[:token])

        # we finally sign him in
        sign_out
        sign_in(:user, user)

        # we force him to have a landing on package sets
        session[:landing] = :package_sets

        SlackDispatcher.new.message("[Wechat] Tourist guide automatically logged-in (`#{user&.id}`)")
        redirect_to customer_referrer_path
        return

      end
    end
    redirect_to root_path
  end

  def failure
    flash[:error] = I18n.t(:wechat_login_fail, scope: :notice)
    redirect_to navigation.back(1)
  end

  private

  def wechat_user_solver
    @wechat_user_solver ||= WechatUserSolver.new(wechat_data).resolve!
  end

  def wechat_data
    {
      provider: request.env["omniauth.auth"].provider,
      unionid: request.env["omniauth.auth"].info.unionid,
      openid: request.env["omniauth.auth"].info.openid,
      nickname: request.env["omniauth.auth"].info.nickname,
      avatar: request.env["omniauth.auth"].info.headimgurl,
      sex: request.env["omniauth.auth"].info.sex,
    }
  end

  def sign_in_user(user)
    flash[:success] = I18n.t(:wechat_login, scope: :notice)
    sign_in(:user, user)
    redirect_to after_sign_in_path_for(user)
  end

end
