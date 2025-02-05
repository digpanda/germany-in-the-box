class WechatLinkCreator
  include Rails.application.routes.url_helpers

  attr_reader :link

  def initialize(link)
    @link = link
  end

  # NOTE : this system used to be more complex
  # we kept the library in case it gets complicated again
  # for now it's just a simple path
  # Laurent, 29/08/2017
  def with_login_and_referrer(referrer)
    url_for(
      action:       'weixin',
      link_id:      link.id,
      controller:   'guest/links',
      host:         ENV['wechat_local_domain'],
      protocol:     'https',
      reference_id: referrer&.reference_id
    )
  end

  def with_referrer(referrer)
    raw_url = url_for(
      action:       'show',
      id:           link.id,
      controller:   'guest/links',
      host:         ENV['wechat_local_domain'],
      protocol:     'https',
      reference_id: referrer&.reference_id
    )
    WechatUrlAdjuster.new(raw_url).adjusted_url
  end
end
