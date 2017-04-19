require 'csv'
require 'net/ftp'

class Shopkeeper::OrdersController < ApplicationController

  attr_accessor :order

  authorize_resource :class => false
  before_action :set_order, :except => [:index]
  before_filter :is_shop_order, :except => [:index]

  layout :custom_sublayout, only: [:index]

  def index
    @orders = current_user.shop.orders.bought_or_unverified.order_by(paid_at: :desc, c_at: :desc).paginate(:page => current_page, :per_page => 10)
  end

  def shipped

    if order.decorate.shippable?
      order.status = :shipped
      order.save
    end

    flash[:success] = I18n.t(:order_sent, scope: :notice)
    redirect_to navigation.back(1)

  end

  def process_order # can't just put `process` it seems to be reserved term in Rails

    unless order.decorate.processable?
      flash[:error] = I18n.t(:order_not_processable, scope: :notice)
      redirect_to(:back)
      return
    end

    # if our partner is borderguru the status will go from custom checkable
    # to custom checking automatically
    if Setting.instance.logistic_partner == :borderguru
      # we don't forget to change status of orders and such
      # only if everything was a success
      order.status = :custom_checkable
    else
      order.status = :custom_checking
    end

    order.save

    # we go back now
    DispatchNotification.new.perform({
                                                      user: order.user,
                                                      title: '你的订单已出货',
                                                      desc: "你的订单已被商家寄出，你可透过物流跟踪连接追踪包裹：#{order.border_guru_link_tracking}"
                                                  })
    flash[:success] = I18n.t(:order_processing, scope: :notice)
    redirect_to navigation.back(1)
  end

  private

  def set_order
    @order = Order.find(params[:id] || params[:order_id])
  end

  def is_shop_order
    order.shop.id == current_user.shop.id
  end

end
