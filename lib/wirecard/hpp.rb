require 'net/http'
require 'digest'

module Wirecard
  class Hpp < Base

    CONFIG = BASE_CONFIG[:hpp]
    DEFAULT_PAYMENT_LANGUAGE = 'en'
    DEFAULT_PAYMENT_CURRENCY = 'CNY'
    ACCEPTED_PAYMENT_METHODS = [nil, :upop, :creditcard]

    attr_reader :user,
                :order,
                :merchant_id,
                :secret_key,
                :amount,
                :request_id,
                :currency,
                :payment_method,
                :hosted_payment_url,
                :default_redirect_url


    def initialize(user, order, credentials={})

      raise Error, "Wrong arguments given" unless valid_credentials?(credentials)

      @payment_method ||= nil #(credentials[:payment_method] || CONFIG[:default_payment_method]).to_sym
      #raise Error, "Payment method not authorized" unless ACCEPTED_PAYMENT_METHODS.include?(payment_method)

      @user                 = user
      @order                = order

      @merchant_id          = credentials[:merchant_id]
      @secret_key           = credentials[:secret_key]

      @request_id           = SecureRandom.uuid
      @amount               = order.decorate.total_sum_in_yuan.to_f.round(2) # this round is necessary
      @currency             = DEFAULT_PAYMENT_CURRENCY

      @hosted_payment_url   = CONFIG[:hosted_payment_url]
      @default_redirect_url = CONFIG[:default_redirect_url]

    end

    def hosted_payment_datas
      transaction_datas.merge(redirection_datas).merge(customer_datas)
    end

    private

    def transaction_datas
      {
        :request_id                => request_id,
        :request_time_stamp        => request_time_stamp,
        :merchant_account_id       => merchant_id,
        :transaction_type          => CONFIG[:transaction_type],
        :requested_amount          => amount,
        :requested_amount_currency => DEFAULT_PAYMENT_CURRENCY,
        :locale                    => DEFAULT_PAYMENT_LANGUAGE,
        :order_number              => "#{order.id}",
        :order_detail              => order.desc,
        :form_url                  => hosted_payment_url,
        :payment_method            => payment_method,
        :request_signature         => digital_signature,
        :psp_name                  => CONFIG[:psp_name],
      }
    end

    def redirection_datas
      {
        :redirect_url              => success_redirect_url.html_safe,
        :success_redirect_url      => success_redirect_url.html_safe,
        :fail_redirect_url         => fail_redirect_url.html_safe,
        :cancel_redirect_url       => cancel_redirect_url.html_safe,
        :processing_redirect_url   => processing_redirect_url.html_safe,
      }
    end

    def customer_datas
      {
        #:first_name                => user.fname,
        #:last_name                 => user.lname,

        :email                     => user.email,
        :phone                     => user.tel,
        :street1                   => order.billing_address.decorate.street_and_number,
        :street2                   => "",
        :city                      => order.billing_address.city,
        :state                     => order.billing_address.province,
        :postal_code               => order.billing_address.zip,
        :country                   => order.billing_address.country.alpha2,
        :ip_address                => customer_ip_address
      }
    end

    def customer_ip_address
      user.last_sign_in_ip || "127.0.0.1"
    end

    def cancel_redirect_url
      "#{default_redirect_url}?state=cancel&"
    end

    def processing_redirect_url
      "#{default_redirect_url}?state=processing&"
    end

    def success_redirect_url
      CONFIG[:success_redirect_url] || "#{default_redirect_url}?state=success&"
    end

    def fail_redirect_url
      CONFIG[:fail_redirect_url] || "#{default_redirect_url}?state=failed&"
    end

    def digital_signature
      Digest::SHA256.hexdigest(signature_hash.values.join.squish)
    end

    def signature_hash

      # WARNING : the order of the hash matters
      {

        :request_time_stamp      => request_time_stamp,
        :request_id              => request_id,
        :merchant_account_id     => merchant_id,
        :transaction_type        => CONFIG[:transaction_type],
        :requested_amount        => amount,
        :request_amount_currency => currency,
        :redirect_url            => success_redirect_url.html_safe,
        :ip_address              => customer_ip_address,
        :secret_key              => secret_key

      }

    end

    def request_time_stamp
      @request_time_stamp ||= Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    def valid_credentials?(credentials)
      credentials[:merchant_id] && credentials[:secret_key]
      # TODO: could check from model in prod (to be sure)
    end

  end
end
