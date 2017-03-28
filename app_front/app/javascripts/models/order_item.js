/**
 * OrderItem Class
 */
var OrderItem = {

  /**
   * Check if user is auth or not via API call
   */
  setQuantity: function(orderItemId, quantity, callback) {

    $.ajax({
      method: "PATCH",
      url: "/api/guest/order_items/"+orderItemId,
      data: {"quantity" : quantity}

    }).done(function(res) {

      callback(res);

    }).error(function(err) {

      if (typeof err == "undefined") {
        return;
      }

      callback({success: false, error: err.responseJSON.error});

    });

  },

  setPackageSetQuantity: function(packageSetId, quantity, callback) {

    $.ajax({
        method: "PATCH",
        url: "/api/guest/package_sets/"+packageSetId+"/set_quantity",
        data: {"quantity" : quantity}

    }).done(function(res) {

        callback(res);

    }).error(function(err) {

      if (typeof err == "undefined") {
        return;
      }

      callback({success: false, error: err.responseJSON.error});

    });

  },

  addProduct: function(productId, quantity, optionIds, callback) {
    $.ajax({
        method: "POST",
        url: "/api/guest/order_items",
        data: {product_id: productId, quantity: quantity, option_ids: optionIds}

    }).done(function(res) {

        callback(res);

    }).error(function(err) {

      if (typeof err == "undefined") {
        return;
      }

      callback({success: false, error: err.responseJSON.error});

    });
  },

    removeProduct: function (orderItemId, callback) {
        $.ajax({
            method: "DELETE",
            url: "/api/guest/order_items/" + orderItemId

        }).done(function (res) {

            callback(res);

        }).error(function (err) {

          if (typeof err == "undefined") {
            return;
          }

          callback({success: false, error: err.responseJSON.error});

        });
    },

    removeOrder: function (orderId, callback) {
        $.ajax({
            method: "DELETE",
            url: "/api/customer/orders/" + orderId

        }).done(function (res) {

            callback(res);

        }).error(function (err) {

          if (typeof err == "undefined") {
            return;
          }

          callback({success: false, error: err.responseJSON.error});

        });
    },

    addPackageSet: function (url, callback) {
        $.ajax({
            method: "PATCH",
            url: url

        }).done(function (res) {

            callback(res);

        }).error(function (err) {

          if (typeof err == "undefined") {
            return;
          }

          callback({success: false, error: err.responseJSON.error});

        });
    }

};

module.exports = OrderItem;
