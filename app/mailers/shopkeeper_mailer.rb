class ShopkeeperMailer < ApplicationMailer
  default from: 'no-reply@germanyinthebox.com'
  layout 'mailers/shopkeeper'

  def notify(recipient_email:'', user_id:'', title:'', url:'', desc:'')
    @recipient_email = recipient_email
    @user = User.where(id: user_id).first
    @title = title
    @desc = desc
    @url = url
    mail to: @recipient_email, subject: "Benachrichtigung von Germany In The Box: #{@title}"
  end
end
