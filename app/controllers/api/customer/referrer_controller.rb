class Api::Customer::ReferrerController < Api::ApplicationController
  attr_reader :referrer

  before_filter :valid_referrer?
  before_filter :valid_group_leader?, only: [:group_insight]
  authorize_resource class: false

  def group_insight
    render json: Referrer.where(referrer_group: current_user.referrer.referrer_group).all
  end

  def qrcode
    render json: { url: guest_referrer_service_qrcode_url(current_user.referrer) }
  end

  # TODO to finish
  def children_insight
    render json: current_user.referrer.children_users
  end

  def services_rates
    @services = Service.active.where(:default_referrer_rate.gt => 0.0).order_by(name: :asc).all
    render json: fetch_services_rates.to_json
  end

  def brands_rates
    @brands = Brand.with_package_sets
    render json: fetch_brands_rates.to_json
  end

  def fetch_brands_rates
    @brands.reduce([]) do |acc, brand|
      if brand.package_sets_referrer_rates_range(current_user) == [0.0]
        acc
      else
        acc << {
          name: brand.name,
          range: brand.decorate.referrer_rate_range(current_user)
        }
      end
    end
  end

  def fetch_services_rates
    @services.reduce([]) do |acc, service|
      acc << {
        name: service.name,
        rate: "#{service.solve_rate(current_user)}%#{I18n.t('referrer.service_rate_label')}"
      }
    end
  end
end
