require_relative 'concerns/having_vendibles'

module BorderGuru
  module Payloads
    class ShippingApi
      include HavingVendibles

      def initialize(order:, shop:, country_of_destination:, currency:)
        I18n.locale = :'zh-CN'
        @order = order
        @shop = shop
        @country_of_destination = country_of_destination
        @currency = currency
      end

      def to_h
        # NOTE : total_price_with_discount_from_product is not meant to stay this way.
        # we should change it as fast as possible. For more details check `having_vendibles.rb`
        product_summaries(@order).merge({
                                            totalPrice: @order.total_price_with_discount_from_product, # @order.total_price_with_discount.to_f,
                                            countryOfOrigin: @shop.country_of_dispatcher.alpha2,
                                            countryOfDestination: @country_of_destination.alpha2,
                                            currency: @currency,
                                            quoteIdentifier: @order.border_guru_quote_id,
                                            merchantOrderId: @order.border_guru_order_id,
                                            storeName: @shop.name,
                                            dimensionalWeight: @order.total_dimensional_weight,
                                            dimensionalWeightScale: WEIGHT_UNIT,
                                            lineItems: line_items,
                                            shippingAddress: [customer_address(@order.shipping_address)],
                                            billingAddress: [customer_address(@order.shipping_address)],
                                            submerchant: submerchant_address(@shop.sender_address),
                                            identificationData: identification_data(@order.shipping_address)
                                        })
      end

      private

      def identification_data(shipping_address)
        {
          identificationNumber: shipping_address.pid,
          identificationName: shipping_address.decorate.chinese_full_name
        } unless Rails.env.test? # if test environment we can't test this part because it has a delay.
      end

      def submerchant_address(address_model)
        {
            company: address_model.company,
            streetName: "#{address_model.street}",
            houseNo: "#{address_model.number}",
            postcode: address_model.zip,
            city: address_model.city,
            state: "#{address_model.province}",
            email: address_model.shop.mail,
            countryCode: address_model.country_code
        }
      end

      def customer_address(address_model)
        {
            firstName: address_model.fname,
            lastName: address_model.lname,
            streetName: "#{address_model.district} #{address_model.street}",
            houseNo: "#{address_model.decorate.chinese_street_number}",
            additionalInfo: "#{address_model.additional}",
            postcode: address_model.zip,
            city: "#{address_model.province} #{address_model.city}",
            country: address_model.country_name,
            telephone: address_model.mobile,
            email: customer_address_email(address_model),
            countryCode: address_model.country_code
        }
      end

      def customer_address_email(address_model)
        address_model.user&.email || @order.user.email
      end

      def line_items
        super @order.order_items.each do |order_item|
          {
              quantity: order_item.quantity
          }
        end
      end
    end
  end
end
