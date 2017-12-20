require 'actionpack/action_caching'

class Guest::HomeController < ApplicationController
  before_filter :admin_redirection, :shopkeeper_redirection
  before_action :set_banner

  def show
    @shops = Shop.can_buy.order_by(position: :asc).all
  end

  def test
  end

  private

    def set_banner
      @banner = Banner.active.where(location: :shops_landing_cover).first
    end

    def admin_redirection
      if identity_solver.potential_admin?
        redirect_to edit_admin_account_path
      end
    end

    def shopkeeper_redirection
      if identity_solver.potential_shopkeeper?
        redirect_to new_guest_shop_application_path
      end
    end
end
