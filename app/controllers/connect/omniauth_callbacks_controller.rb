class Connect::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # skip CSRF on create.
  skip_before_filter :verify_authenticity_token
  skip_before_action :solve_silent_login # this is useful for #referrer

  # QRCode Wechat classic login system
  def wechat
    if wechat_user_solver.success?
      # is it a new user ?
      handle_after_sign_up! wechat_user_solver.data[:customer]
      sign_in_user wechat_user_solver.data[:customer]
    else
      failure
    end
  end

  # QRCode Wechat tour guide registration
  # it's only a way to group people.
  # TODO : could be arranged using
  # the same system than the global one
  def referrer
    if params[:code]
      wechat_api_connect_solver = WechatApi::ConnectSolver.new(params[:code]).resolve

      # this is taken from application controller
      if wechat_api_connect_solver.success?
        user = wechat_api_connect_solver.data[:customer]

        # we turn him into a real referrer
        ReferrerMaker.new(user).convert!(group_token: params[:token])
        SlackDispatcher.new.message("ReferrerMaker was called for user `#{user&.id}`")

        # is it a new user ?
        handle_after_sign_up! user

        # we force him to have a landing on package sets
        session[:landing] = :package_sets
        # we finally sign him in
        sign_in_user user
        return

      end
    end
    redirect_to root_path
  end

  def failure
    flash[:error] = I18n.t('notice.wechat_login_fail')
    redirect_to navigation.back(1)
  end

  private

    def slack
      @slack ||= SlackDispatcher.new
    end

    def handle_after_sign_up!(user)
      if user.freshly_created?
        AfterSignupHandler.new(request, user).solve
      end
    end

    def wechat_user_solver
      @wechat_user_solver ||= WechatUserSolver.new(wechat_data).resolve
    end

    def wechat_data
      {
        provider: request.env['omniauth.auth'].provider,
        unionid: request.env['omniauth.auth'].info.unionid,
        openid: request.env['omniauth.auth'].info.openid,
        nickname: request.env['omniauth.auth'].info.nickname,
        avatar: request.env['omniauth.auth'].info.headimgurl,
        sex: request.env['omniauth.auth'].info.sex,
      }
    end

    def sign_in_user(user)
      flash[:success] = I18n.t('notice.wechat_login')
      sign_in(:user, user)
      redirect_to after_sign_in_path_for(user)
    end
end
