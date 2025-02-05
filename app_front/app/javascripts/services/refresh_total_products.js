/**
 * RefreshTotalProducts Class
 */
var RefreshTotalProducts = {

  /**
   * Refresh it
   */
  perform: function() {

    var Cart = require('javascripts/models/cart');
    Cart.total(function(res) {
      $(".js-total-products").html(res.datas)
      RefreshTotalProducts.resolveHiding(res.datas);
    });

  },

  resolveHiding: function(total) {
    if (total > 0) {
      $('.js-total-products').removeClass('+hidden');
    } else {
      $('.js-total-products').addClass('+hidden');
    }
  }

}

module.exports = RefreshTotalProducts;
