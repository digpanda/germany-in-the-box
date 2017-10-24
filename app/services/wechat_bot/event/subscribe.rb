# when someone just subscribes to our service channel
# this is called
class WechatBot
  class Event < Base
    class Subscribe < Base
      attr_reader :user

      def initialize(user)
        @user = user
      end

      # when the user subscribe it'll trigger this method
      def handle
        messenger.text("""
        欢迎#{user.decorate.readable_who}访问来因盒！\n
  🎊德国精品: 来因盒首页，各类电商精品和海外服务汇总\n
  👔海外综合: 本地专业团队为您提供海外房产、金融投资、保险、医疗服务\n
  聊客服下单: 直接跟客服聊天帮你下单\n
  ---购买下单注意事项---\n
  请填写收件人的收件地址，手机号(用于发货通知和快递员送货)，身份证号码(中国海关通关要求)\n
  微信内访问来因盒，首选微信支付一步完成。 支付宝需要拷贝粘贴支付宝链接到手机浏览器里完成支付\n
  所有商品阳光清关，包邮包税\n\n\n
  --------------------\n
  👑什么值得买: 一些欧洲、德国品牌为什么值得买\n\n\n
  🚚批发定制: 批发或定制产品采购请添加微信客服与我们联系\n
  ✅商业合作: 与来因盒平台进行商业合作请通过这里与我们联系\n
  """).send
      end
    end
  end
end
