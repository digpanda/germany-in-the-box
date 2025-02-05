module Application
  module Categories
    extend ActiveSupport::Concern

    included do
      before_action :set_categories
    end

    # this is mainly for the menu
    def set_categories
      if identity_solver.section == :customer
        @categories = Category.showable.order(position: :asc).all
      end
    end
  end
end
