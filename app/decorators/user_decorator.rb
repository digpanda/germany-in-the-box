class UserDecorator < Draper::Decorator

  PICTURE_URL = '/images/icons/default_user_pic.png'

  include Concerns::Imageable

  delegate_all
  decorates :user

  def full_name
    "#{fname} #{lname}"
  end

  def avatar
    if pic.url.nil?
     PICTURE_URL
    else
      image_url(:pic, :thumb)
    end
  end

  def new_notifications?
    notifications.unreads.count > 0
  end

end
