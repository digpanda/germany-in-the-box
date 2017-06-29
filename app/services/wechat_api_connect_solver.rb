class WechatApiConnectSolver < BaseService

  attr_reader :code

  def initialize(code)
    @code = code
  end

  def resolve!
    if connect_user.success?
      return_with(:success, customer: connect_user.data[:customer])
    else
      return_with(:error, error: connect_user.error)
    end
  end

  # we will try to log-in the customer from the 2 APIs
  # if the first one succeed and we can already find the user from the given data
  # we stop there and return the customer
  # if the first one is not enough, we use a 2nd API call and use it on wechat_user_solver
  # which will return a customer freshly created or an old one
  def connect_user
    @connect_user ||= begin
      return return_with(:error, "Access token is wrong") if access_token_gateway['errcode']
      return return_with(:error, "User info is wrong") if user_info_gateway['errcode']

      unless wechat_user_solver.success?
        return return_with(:error, wechat_user_solver.error)
      end

      return_with(:success, customer: wechat_user_solver.data[:customer])
    end
  end

  def openid
    access_token_gateway['openid']
  end

  def unionid
    access_token_gateway['unionid']
  end

  def access_token
    access_token_gateway['access_token']
  end

  private

  def wechat_user_solver
    @wechat_user_solver ||= WechatUserSolver.new(wechat_data).resolve!
  end

  def wechat_data
    {
      provider: :wechat,
      unionid: user_info_gateway['unionid'],
      openid: user_info_gateway['openid'],
      nickname: user_info_gateway['nickname'],
      avatar: user_info_gateway['headimgurl'],
      sex: user_info_gateway['sex'],
    }
  end

  def access_token_gateway
    @access_token_gateway ||= get_url oauth2_access_token_url
  end

  def user_info_gateway
    @user_info_gateway ||= get_url userinfo_access_token_url
  end

  def oauth2_access_token_url
    "https://api.wechat.com/sns/oauth2/access_token?appid=#{Rails.application.config.wechat[:username_mobile]}&secret=#{Rails.application.config.wechat[:password_mobile]}&code=#{code}&grant_type=authorization_code"
  end

  def userinfo_access_token_url
    "https://api.wechat.com/sns/userinfo?access_token=#{access_token}&openid=#{openid}"
  end

  def get_url(url)
    response = Net::HTTP.get(URI.parse(url))
    JSON.parse(response)
  end

end
