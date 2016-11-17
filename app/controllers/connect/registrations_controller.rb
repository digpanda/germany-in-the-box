class Connect::RegistrationsController < Devise::RegistrationsController

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  include Base64ToUpload

  before_action(:only =>  [:create, :update]) {
    base64_to_uploadedfile :user, :pic
  }

  respond_to :html, :json

  def new

    session[:signup_advice_counter] = 1
    build_resource({})
    yield resource if block_given?
    respond_with resource
  end

  def cancel_signup
    session.delete(:signup_advice_counter)
  end

  def create

    build_resource(sign_up_params)

      yield resource if block_given?
      resource.save

      if resource.persisted?

        if resource.active_for_authentication?

          flash[:success] = I18n.t(:success_subscription, scope: :notice)

          sign_up(resource_name, resource)

          sign_in(:user, User.find(resource.id)) # auto sign in

          if resource.decorate.customer?

            EmitNotificationAndDispatchToUser.new.perform({
              :user => resource,
              :title => '注册成功，欢迎光临来因盒！',
              :desc => "亲，欢迎你到来因盒购物。"
            })

          elsif resource.decorate.shopkeeper?

             EmitNotificationAndDispatchToUser.new.perform({
              :user => resource,
              :title => 'Wilkommen bei Germany In The Box !',
              :desc => "Vielen Dank für Ihren Antrag. Wir werden uns bald mit Ihnen in Verbindung setzten."
            })

          end

          respond_with resource, location: after_sign_up_path_for(resource)
          return

        else
          set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end

        session.delete(:signup_advice_counter)
      else
        clean_up_passwords resource
        set_minimum_password_length

        session[:signup_advice_counter] = 1
        flash[:error] = resource.errors.full_messages.join(', ')
        render :new

      end

  end

  protected

  def after_inactive_sign_up_path_for(resource)
    flash[:info] = I18n.t(:email_confirmation_msg, scope: :top_menu)
    popular_products_path
  end

  def configure_devise_permitted_parameters
    registration_params = [:fname, :lname, :email, :password, :password_confirmation, :birth, :gender, :pic]

    if params[:action] == 'update'
      devise_parameter_sanitizer.for(:account_update) {
          |u| u.permit(registration_params << :current_password)
      }
    elsif params[:action] == 'create'
      devise_parameter_sanitizer.for(:sign_up) {
          |u| u.permit(registration_params)
      }
    end
  end
end
