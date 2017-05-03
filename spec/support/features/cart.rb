module Helpers
  module Features
    module Cart

      module_function

      def go_to_cart!
        page.first('#cart').trigger('click')
        expect(page).to have_content("总计")
      end

      # go to the package set area
      # add the first one to the cart
      def package_to_cart!
        visit guest_package_sets_path
        page.first(".package-select").trigger('click')
        expect(page).to have_content("加入购物车")
        page.first("#add-package-set").trigger('click')
      end

      # go to the product page and add it to our cart
      # then goes to the shop page
      def product_to_cart!(product)
        visit guest_product_path(product)
        on_product_page?
        page.first('#js-add-to-cart').click
        expect(page).to have_content("产品添加成功") # success
        visit guest_shop_path(product.shop)
      end

      # make and apply a coupon made on the fly
      # you must be on the cart page to make it work
      def make_and_apply_coupon!(code:"AAA")
        FactoryGirl.create(:coupon, code: code)
        fill_in 'coupon[code]', :with => code
        click_on '使用'
        expect(page).to have_content "此优惠券已被成功使用。"
      end

    end
  end
end
