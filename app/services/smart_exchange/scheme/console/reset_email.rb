module SmartExchange
  module Scheme
    class Console < Base
      class ResetEmail < Base

        # we will reset the email to a fake wechat one
        def request
          'reset email'
        end

        def response
          user.email = "#{user.wechat_unionid}@wechat.com"
          messenger.text! "User email : #{user.email}"
          user.skip_reconfirmation!
          user.save(validate: false)
          user.reload
          messenger.text! "Your unvalid email is now : #{user.email}"
        end
      end
    end
  end
end
