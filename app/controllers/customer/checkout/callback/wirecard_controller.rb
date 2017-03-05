class Customer::Checkout::Callback::WirecardController < ApplicationController

  authorize_resource :class => false
  layout :default_layout
  protect_from_forgery :except => [:success, :fail, :cancel, :processing]

  def success

    callback = checkout_callback.wirecard!
    unless callback.success?
      SlackDispatcher.new.message("Error checkout callback #{checkout_callback.error}")
      flash[:error] = callback.error
      redirect_to navigation.back(2)
      return
    end

    order = OrderPayment.where(:request_id => params[:request_id]).first.order
    checkout_callback.manage_stocks!(order, cart_manager)
    checkout_callback.manage_logistic!(order)

    # whatever happens with BorderGuru, if the payment is a success we consider
    # the transaction / order as successful, we will deal with BorderGuru through Slack / Emails
    flash[:success] = I18n.t(:checkout_ok, scope: :checkout)
    redirect_to customer_orders_path
  end

  # make the user return to the previous page
  def cancel
    redirect_to navigation.back(2)
  end

  # alias of success
  def processing
    success
  end

  # the card processing failed
  def fail
    flash[:error] = I18n.t(:failed, scope: :payment)
    warn_developers(Wirecard::Base::Error.new, "Something went wrong during the payment.")

    callback = CheckoutCallback.new(current_user, params, :failed).wirecard!
    unless callback.success?
      SlackDispatcher.new.message("Error checkout callback #{checkout_callback.error}")
      flash[:error] = callback.error
    end

    redirect_to navigation.back(2)
  end

  private

  def checkout_callback(forced_status: nil)
    @checkout_callback ||= CheckoutCallback.new(current_user, params)
  end

end
