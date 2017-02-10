(function() {
  'use strict';

  var globals = typeof window === 'undefined' ? global : window;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};
  var aliases = {};
  var has = ({}).hasOwnProperty;

  var expRe = /^\.\.?(\/|$)/;
  var expand = function(root, name) {
    var results = [], part;
    var parts = (expRe.test(name) ? root + '/' + name : name).split('/');
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function expanded(name) {
      var absolute = expand(dirname(path), name);
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var hot = null;
    hot = hmr && hmr.createHot(name);
    var module = {id: name, exports: {}, hot: hot};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var expandAlias = function(name) {
    return aliases[name] ? expandAlias(aliases[name]) : name;
  };

  var _resolve = function(name, dep) {
    return expandAlias(expand(dirname(name), dep));
  };

  var require = function(name, loaderPath) {
    if (loaderPath == null) loaderPath = '/';
    var path = expandAlias(name);

    if (has.call(cache, path)) return cache[path].exports;
    if (has.call(modules, path)) return initModule(path, modules[path]);

    throw new Error("Cannot find module '" + name + "' from '" + loaderPath + "'");
  };

  require.alias = function(from, to) {
    aliases[to] = from;
  };

  var extRe = /\.[^.\/]+$/;
  var indexRe = /\/index(\.[^\/]+)?$/;
  var addExtensions = function(bundle) {
    if (extRe.test(bundle)) {
      var alias = bundle.replace(extRe, '');
      if (!has.call(aliases, alias) || aliases[alias].replace(extRe, '') === alias + '/index') {
        aliases[alias] = bundle;
      }
    }

    if (indexRe.test(bundle)) {
      var iAlias = bundle.replace(indexRe, '');
      if (!has.call(aliases, iAlias)) {
        aliases[iAlias] = bundle;
      }
    }
  };

  require.register = require.define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has.call(bundle, key)) {
          require.register(key, bundle[key]);
        }
      }
    } else {
      modules[bundle] = fn;
      delete cache[bundle];
      addExtensions(bundle);
    }
  };

  require.list = function() {
    var list = [];
    for (var item in modules) {
      if (has.call(modules, item)) {
        list.push(item);
      }
    }
    return list;
  };

  var hmr = globals._hmr && new globals._hmr(_resolve, require, modules, cache);
  require._cache = cache;
  require.hmr = hmr && hmr.wrap;
  require.brunch = true;
  globals.require = require;
})();

(function() {
var global = window;
var __makeRelativeRequire = function(require, mappings, pref) {
  var none = {};
  var tryReq = function(name, pref) {
    var val;
    try {
      val = require(pref + '/node_modules/' + name);
      return val;
    } catch (e) {
      if (e.toString().indexOf('Cannot find module') === -1) {
        throw e;
      }

      if (pref.indexOf('node_modules') !== -1) {
        var s = pref.split('/');
        var i = s.lastIndexOf('node_modules');
        var newPref = s.slice(0, i).join('/');
        return tryReq(name, newPref);
      }
    }
    return none;
  };
  return function(name) {
    if (name in mappings) name = mappings[name];
    if (!name) return;
    if (name[0] !== '.' && pref) {
      var val = tryReq(name, pref);
      if (val !== none) return val;
    }
    return require(name);
  }
};
require.register("javascripts/controllers/admin/shops/package_sets.js", function(exports, require, module) {
'use strict';

/**
* PackageSets Class
*/
var PackageSets = {

  /**
  * Initializer
  */
  init: function init() {

    this.handleSelect();
  },

  handleSelect: function handleSelect() {

    $(document).ready(function () {
      $('select[name*="[product_id]"]').each(function (el) {
        PackageSets.refreshSku(this);
      });
    });

    $('select[name*="[product_id]"]').on('change', function (el) {
      PackageSets.refreshSku(this);
    });
  },

  refreshSku: function refreshSku(self) {

    var productSelector = $(self);
    var ProductSku = require("javascripts/models/product_sku");
    var productId = productSelector.val();

    if (_.isEmpty(productId)) {
      return false;
    }

    ProductSku.all(productId, function (res) {

      if (res.success == true) {
        (function () {

          var skuSelector = productSelector.parent().parent().find('select[name*="[sku_id]"]');
          var possibleSkuId = productSelector.parent().parent().find('.js-sku-id');

          skuSelector.html('<option value="">-</option>');

          res.skus.forEach(function (sku) {

            skuSelector.append("<option value=\"" + sku.id + "\">" + sku.option_names + "</option>");

            // If we are editing we should setup the pre-selected sku id
            var nearSkuId = possibleSkuId.data().skuId;
            skuSelector.val(nearSkuId);
          });
        })();
      }
    });
  }

};

module.exports = PackageSets;
});

require.register("javascripts/controllers/admin/shops/products.js", function(exports, require, module) {
'use strict';

/**
 * Products Class
 */
var Products = {

  /**
   * Initializer
   */
  init: function init() {

    this.handleDutyCategoryChange();
  },

  /**
   * We check if the duty category exists through AJAX
   * and throw it / an error on the display
   * @return {void}
   */
  handleDutyCategoryChange: function handleDutyCategoryChange() {

    Products.refreshDutyCategory('#duty-category');

    $('#duty-category').on('keyup', function (e) {

      Products.refreshDutyCategory(this);
    });
  },

  refreshDutyCategory: function refreshDutyCategory(selector) {

    var DutyCategory = require("javascripts/models/duty_category");
    var dutyCategoryId = $(selector).val();

    if (dutyCategoryId === '' || typeof dutyCategoryId == "undefined") {
      return;
    }

    DutyCategory.find(dutyCategoryId, function (res) {

      if (res.success) {
        Products.showDutyCategory(res.datas.duty_category);
      } else {
        Products.throwNotFoundDutyCategory();
      }
    });
  },

  showDutyCategory: function showDutyCategory(duty_category) {

    $('.js-duty-category').html('<span class="+blue">' + duty_category.name + '</span>');
  },

  throwNotFoundDutyCategory: function throwNotFoundDutyCategory() {

    $('.js-duty-category').html('<span class="+red">Duty Category not found</span>');
  }

};

module.exports = Products;
});

require.register("javascripts/controllers/admin/shops/products/skus.js", function(exports, require, module) {
"use strict";

/**
 * ProductsSkus Class
 */
var ProductsSkus = {

  /**
   * Initializer
   */
  init: function init() {

    /**
     * Since the system is cloned on the admin we try
     * to limit the code duplication by abstracting into a library
     */
    var Skus = require("javascripts/lib/skus");
    Skus.setup();
  }

};

module.exports = ProductsSkus;
});

require.register("javascripts/controllers/admin/shops/products/variants.js", function(exports, require, module) {
"use strict";

/**
 * ProductsVariants Class
 */
var ProductsVariants = {

  /**
   * Initializer
   */
  init: function init() {

    /**
     * Since the system is cloned on the admin we try
     * to limit the code duplication by abstracting into a library
     */
    var Variants = require("javascripts/lib/variants");
    Variants.setup();
  }

};

module.exports = ProductsVariants;
});

require.register("javascripts/controllers/customer/cart/show.js", function(exports, require, module) {
'use strict';

/**
 * CustomerCartShow class
 */
var CustomerCartShow = {

  click_chain: 0, // init click chain system
  chain_timing: 500, // in ms

  /**
   * Initializer
   */
  init: function init() {

    this.multiSelectSystem();
    this.orderItemHandleQuantity();
  },

  multiSelectSystem: function multiSelectSystem() {

    $('select.sku-variants-options').multiselect({
      enableCaseInsensitiveFiltering: true,
      maxHeight: 400
    }).multiselect('disable');
  },

  orderItemHandleQuantity: function orderItemHandleQuantity() {

    $('.js-set-quantity-minus').click(function (e) {

      e.preventDefault();
      CustomerCartShow.click_chain++;

      var orderItemId = $(this).data('orderItemId');
      var orderShopId = $(this).data('orderShopId');
      var currentQuantity = $('#order-item-quantity-' + orderItemId).val();
      var originQuantity = currentQuantity;

      if (currentQuantity > 1) {
        currentQuantity--;
        CustomerCartShow.orderItemSetQuantity(orderShopId, orderItemId, originQuantity, currentQuantity);
      }
    });

    $('.js-set-quantity-plus').click(function (e) {

      e.preventDefault();
      CustomerCartShow.click_chain++;

      var orderItemId = $(this).data('orderItemId');
      var orderShopId = $(this).data('orderShopId');
      var currentQuantity = $('#order-item-quantity-' + orderItemId).val();
      var originQuantity = currentQuantity;

      currentQuantity++;
      CustomerCartShow.orderItemSetQuantity(orderShopId, orderItemId, originQuantity, currentQuantity);
    });
  },

  loaded: function loaded() {

    $('.js-loader').hide();
    $('#cart-total').show();
  },

  loading: function loading() {

    $('.js-loader').show();
    $('#cart-total').hide();
  },

  orderItemSetQuantity: function orderItemSetQuantity(orderShopId, orderItemId, originQuantity, orderItemQuantity) {

    // We first setup a temporary number before the AJAX callback
    $('#order-item-quantity-' + orderItemId).val(orderItemQuantity);
    CustomerCartShow.loading();

    var current_click_chain = CustomerCartShow.click_chain;

    setTimeout(function () {

      // We basically prevent multiple click by considering only the last click as effective
      // It won't call the API if we clicked more than once on the + / - within the second
      if (current_click_chain == CustomerCartShow.click_chain) {
        CustomerCartShow.processQuantity(orderShopId, orderItemId, originQuantity, orderItemQuantity);
      }
    }, CustomerCartShow.chain_timing);
  },

  processQuantity: function processQuantity(orderShopId, orderItemId, originQuantity, orderItemQuantity) {

    var OrderItem = require("javascripts/models/order_item");
    OrderItem.setQuantity(orderItemId, orderItemQuantity, function (res) {

      var Messages = require("javascripts/lib/messages");

      if (res.success === false) {

        CustomerCartShow.rollbackQuantity(originQuantity, orderItemId, res);
        CustomerCartShow.loaded();
        Messages.makeError(res.error);
      } else {

        // We first refresh the value in the HTML
        CustomerCartShow.resetHeaderCartQuantity();
        CustomerCartShow.resetDisplay(orderItemQuantity, orderItemId, orderShopId, res);
        CustomerCartShow.loaded();

        var refreshTotalProducts = require('javascripts/services/refresh_total_products');
        refreshTotalProducts.perform();
      }
    });
  },

  resetHeaderCartQuantity: function resetHeaderCartQuantity() {

    /**
     * NOTE : This system was cancelled because we don't show
     * the number of product within the cart
     * - Laurent, 23/01/2017
     */
    // var total = 0;
    //
    // $('[id^="order-item-quantity-"]').each(function(e) {
    //   total += parseInt($(this).val());
    //   $('#total-products').html(total);
    // })

  },

  rollbackQuantity: function rollbackQuantity(originQuantity, orderItemId, res) {

    // TODO : possible improvement
    // instead of rolling back completely we could make a system
    // to try again with different quantity

    // We try to get back the correct value from AJAX if we can
    // To avoid the system to show a wrong quantity on the display
    if (typeof res.original_quantity != "undefined") {
      originQuantity = res.original_quantity;
    }

    // We rollback the quantity
    $('#order-item-quantity-' + orderItemId).val(originQuantity);
  },

  resetDisplay: function resetDisplay(orderItemQuantity, orderItemId, orderShopId, res) {

    // Quantity changes
    $('#order-item-quantity-' + orderItemId).val(orderItemQuantity);

    // Total changes
    $('#order-total-price-with-taxes-' + orderShopId).html(res.data.total_price_with_taxes);
    $('#order-shipping-cost-' + orderShopId).html(res.data.shipping_cost);
    $('#order-end-price-' + orderShopId).html(res.data.end_price);

    // Discount management
    if (typeof res.data.total_price_with_discount != "undefined") {
      $('#order-total-price-with-extra-costs-' + orderShopId).html(res.data.total_price_with_extra_costs);
      $('#order-total-price-with-discount-' + orderShopId).html(res.data.total_price_with_discount);
      $('#order-discount-display-' + orderShopId).html(res.data.discount_display);
    }
  }

};

module.exports = CustomerCartShow;
});

require.register("javascripts/controllers/customer/checkout/gateway.js", function(exports, require, module) {
"use strict";

/**
 * CustomerGatewayCreate class
 */
var CustomerGatewayCreate = {

  /**
   * Initializer
   */
  init: function init() {

    this.postBankDetails();
  },

  /**
   * Post bank details to the `form_url`
   */
  postBankDetails: function postBankDetails() {

    var Casing = require("javascripts/lib/casing");
    var PostForm = require("javascripts/lib/post_form.js");

    var bankDetails = $("#bank-details")[0].dataset;
    var parsedBankDetails = Casing.objectToUnderscoreCase(bankDetails);

    PostForm.send(parsedBankDetails, parsedBankDetails['form_url']);
  }

};

module.exports = CustomerGatewayCreate;
});

require.register("javascripts/controllers/customer/checkout/payment_method.js", function(exports, require, module) {
'use strict';

/**
 * CustomerCheckoutPaymentMethod class
 */
var CustomerCheckoutPaymentMethod = {

  /**
   * Initializer
   */
  init: function init() {

    this.handleMethodSelection();
  },

  /**
   * Will process after someone click to go through the payment gateway (blank page)
   */
  handleMethodSelection: function handleMethodSelection() {

    $('button[type=submit]').click(function (e) {

      $('#payment_method_area').hide();
      $('#after_payment_method_area').removeClass('hidden');
    });
  }

};

module.exports = CustomerCheckoutPaymentMethod;
});

require.register("javascripts/controllers/customer/orders/addresses.js", function(exports, require, module) {
'use strict';

/**
 * OrdersAddresses class
 */
var OrdersAddresses = {

  /**
   * Initializer
   */
  init: function init() {

    this.newAddressForm();
  },

  /**
   * When someone clicks on "enter new address" a form will show up
   */
  newAddressForm: function newAddressForm() {

    $('#button-new-address').on('click', function (e) {

      $('#button-new-address').addClass('+hidden');
      $('#new-address').removeClass('+hidden');

      // we reset the sticky footer because it makes useless spaces
      var Footer = require('javascripts/starters/footer');
      Footer.processStickyFooter();
    });
  }

};

module.exports = OrdersAddresses;
});

require.register("javascripts/controllers/customer/orders/show.js", function(exports, require, module) {
'use strict';

/**
 * OrdersShow class
 */
var OrdersShow = {

  /**
   * Initializer
   */
  init: function init() {

    this.multiSelectSystem();
  },

  multiSelectSystem: function multiSelectSystem() {

    $('select.sku-variants-options').multiselect({
      enableCaseInsensitiveFiltering: true,
      maxHeight: 400
    }).multiselect('disable');
  }

};

module.exports = OrdersShow;
});

require.register("javascripts/controllers/guest/feedback.js", function(exports, require, module) {
'use strict';

/**
 * GuestFeedback Class
 */
var GuestFeedback = {

  /**
   * Initializer
   */
  init: function init() {

    var Preloader = require("javascripts/lib/preloader");
    Preloader.dispatchLoader('#external-script', '.js-loader', 'iframe#WJ_survey');
  }

};

module.exports = GuestFeedback;
});

require.register("javascripts/controllers/guest/products/show.js", function(exports, require, module) {
'use strict';

var Translation = require("javascripts/lib/translation");
/**
 * ProductsShow Class
 */
var ProductsShow = {

  /**
   * Initializer
   */
  init: function init() {

    this.handleProductGalery();
    this.handleSkuChange();
    this.handleQuantityChange();
    this.manageAddProduct();
  },

  /**
   * Grow or reduce price on the display
   * @param  {String} [option] `grow` or `reduce` price
   * @param  {Integer} old_quantity    the original old quantity
   * @param  {String} selector        the area the HTML had to be changed
   * @return {void}
   */
  changePrice: function changePrice() {
    var option = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 'grow';
    var old_quantity = arguments[1];
    var selector = arguments[2];


    if (typeof $(selector) == 'undefined') {
      return;
    }

    old_quantity = parseInt(old_quantity);
    var old_price = $(selector).html();
    var unit_price = parseFloat(old_price) / parseInt(old_quantity);

    if (option == 'grow') {
      var new_quantity = old_quantity + 1;
    } else if (option == 'reduce') {
      var new_quantity = old_quantity - 1;
    }

    var new_price = unit_price * new_quantity;
    $(selector).html(new_price.toFixed(2));
  },

  /**
   * Handle the quantity change with different selector (minus or plus)
   * @return {void}
   */
  handleQuantityChange: function handleQuantityChange() {

    this.manageQuantityMinus();
    this.manageQuantityPlus();
  },

  /**
   * Reduce the quantity by clicking on the minus symbol on the page
   * @return {void}
   */
  manageQuantityMinus: function manageQuantityMinus() {

    $('#quantity-minus').on('click', function (e) {

      e.preventDefault();
      var quantity = $('#quantity').val();;

      if (quantity > 1) {

        ProductsShow.changePrice('reduce', quantity, '#product_discount_with_currency_yuan .amount');
        ProductsShow.changePrice('reduce', quantity, '#product_discount_with_currency_euro .amount');

        // We show per unit
        //ProductsShow.changePrice('reduce', quantity, '#product_fees_with_currency_yuan .amount');

        ProductsShow.changePrice('reduce', quantity, '#product_price_with_currency_yuan .amount');
        ProductsShow.changePrice('reduce', quantity, '#product_price_with_currency_euro .amount');
        quantity--;
      }
      $('#quantity').val(quantity);
    });
  },

  /**
   * Grow the quantity by clicking on the plus symbol on the page
   * @return {void}
   */
  manageQuantityPlus: function manageQuantityPlus() {

    $('#quantity-plus').on('click', function (e) {

      e.preventDefault();
      var quantity = $('#quantity').val();

      if (quantity < $('#quantity').data('max')) {

        ProductsShow.changePrice('grow', quantity, '#product_discount_with_currency_yuan .amount');
        ProductsShow.changePrice('grow', quantity, '#product_discount_with_currency_euro .amount');

        // We show per unit only because it's not growable accurately
        //ProductsShow.changePrice('grow', quantity, '#product_fees_with_currency_yuan .amount');
        ProductsShow.changePrice('grow', quantity, '#product_price_with_currency_yuan .amount');
        ProductsShow.changePrice('grow', quantity, '#product_price_with_currency_euro .amount');
        quantity++;
      }
      $('#quantity').val(quantity);
    });
  },

  /**
   * Adds the product to the cart when clicking on 'Add Product'
   * @return {void}
   */

  manageAddProduct: function manageAddProduct() {

    $('#js-add-to-cart').on('click', function (e) {

      e.preventDefault();

      var OrderItem = require("javascripts/models/order_item");
      var quantity = $('#quantity').val();
      var option_ids = $('#option_ids').val();
      var sku_product_id = $('#sku_product_id').val();
      var redirection = $(this).data('redirection');

      OrderItem.addProduct(sku_product_id, quantity, option_ids, function (res) {

        var Messages = require("javascripts/lib/messages");

        if (res.success === true) {

          Messages.makeSuccess(res.msg);

          var refreshTotalProducts = require('javascripts/services/refresh_total_products');
          refreshTotalProducts.perform();

          // We redirect the user even tho it's AJAX call (not waiting for answer)
          // if (typeof redirection != "undefined") {
          //   window.location.href = redirection;
          //   // window.location.href = $("#js-info").data("navigationBack");
          // }
        } else {

          Messages.makeError(res.error);
        }
      });
    });
  },

  /**
   * Manage the whole gallery selection
   * @return {void}
   */
  handleProductGalery: function handleProductGalery() {

    $(document).on('click', '#gallery a', function (e) {

      var image = $(this).data('image');
      var zoomImage = $(this).data('zoom-image');

      e.preventDefault();

      // Changing the image when we click on any thumbnail of the #gallery
      // We also manage a small pre-loader in case it's slow.
      ProductsShow.changeMainImage(image, '.js-loader');

      /*
      $('#main_image').magnify({
        speed: 0,
        src: zoomImage,
      });*/
    });

    // We don't forget to trigger the click to load the first image
    $('#gallery a:first').trigger('click');

    // We hide the button because
    // if there's only one element
    ProductsShow.manageClickableImages();
  },

  /**
   * Hide the thumbnail clickables images of the gallery
   * If not needed (such as one image total)
   * @return {void}
   */
  manageClickableImages: function manageClickableImages() {

    if ($('#gallery a').size() <= 1) {
      $('#gallery a:first').hide();
    }
  },

  /**
   * Load a new main image from a thumbanil
   * @param  {String} image new image source
   * @param  {String} loader_selector loader to display
   * @return {void}
   */
  changeMainImage: function changeMainImage(image, loader_selector) {

    var ContentPreloader = require("javascripts/lib/content_preloader");
    ContentPreloader.process($('#main_image').attr('src', image), loader_selector);
  },

  /**
   * When the customer change of sku selection, it refreshes some datas (e.g. price)
   */
  handleSkuChange: function handleSkuChange() {

    $('select#option_ids').change(function () {

      var productId = $(this).attr('product_id');
      var optionIds = $(this).val().split(',');

      var ProductSku = require("javascripts/models/product_sku");
      var Messages = require("javascripts/lib/messages");

      ProductSku.show(productId, optionIds, function (res) {

        if (res.success === false) {

          Messages.makeError(res.error);
        } else {

          ProductsShow.skuChangeDisplay(productId, res);
        }
      });
    });
  },

  skuHideDiscount: function skuHideDiscount() {

    $('#product_discount_with_currency_euro').hide();
    $('#product_discount_with_currency_yuan').hide();
    $('#product_discount').hide();

    $('#product_discount').removeClass('+discount');
  },

  skuShowDiscount: function skuShowDiscount() {

    $('#product_discount_with_currency_euro').show();
    $('#product_discount_with_currency_yuan').show();
    $('#product_discount').show();

    $('#product_discount').addClass('+discount');
  },

  /**
   * Change the display of the product page sku datas
   */
  skuChangeDisplay: function skuChangeDisplay(productId, skuDatas) {

    ProductsShow.refreshSkuQuantitySelect(productId, skuDatas['quantity']); // productId is useless with the new system (should be refactored)

    $('#product_fees_with_currency_yuan').html(skuDatas['fees_with_currency_yuan']);
    $('#product_price_with_currency_yuan').html(skuDatas['price_with_currency_yuan']);
    $('#product_price_with_currency_euro').html(skuDatas['price_with_currency_euro']);
    $('#quantity-left').html(skuDatas['quantity']);

    $('#quantity').val(1); // we reset the quantity to 1

    if (skuDatas['discount'] == 0) {

      ProductsShow.skuHideDiscount();
    } else {

      ProductsShow.skuShowDiscount();

      $('#product_discount_with_currency_euro').html('<span class="+barred"><span class="+dark-grey">' + skuDatas['price_before_discount_in_euro'] + '</span></span>');
      $('#product_discount_with_currency_yuan').html('<span class="+barred"><span class="+black">' + skuDatas['price_before_discount_in_yuan'] + '</span></span>');
      $('#product_discount').html(skuDatas['discount_with_percent'] + '<br/>');
    }

    ProductsShow.refreshSkuSecondDescription(skuDatas['data_format']);

    ProductsShow.refreshSkuAttachment(skuDatas['data_format'], skuDatas['file_attachment']);
    ProductsShow.refreshSkuThumbnailImages(skuDatas['images']);

    ProductsShow.handleProductGalery();
  },

  /**
   * Refresh sku quantity select (quantity dropdown)
   */
  refreshSkuQuantitySelect: function refreshSkuQuantitySelect(productId, quantity) {

    var quantity_select = $('#product_quantity_' + productId).empty();

    for (var i = 1; i <= parseInt(quantity); ++i) {
      quantity_select.append('<option value="' + i + '">' + i + '</option>');
    }
  },

  /**
   * Refresh sku thumbnail images list
   */
  refreshSkuThumbnailImages: function refreshSkuThumbnailImages(images) {

    for (var i = 0; i < images.length; i++) {

      var image = images[i];

      // protection to avoid empty images
      // in case of transfer bug to the front-end
      if (image.fullsize != null) {

        if ($('#thumbnail-' + i).length > 0) {
          $('#thumbnail-' + i).html('<a href="#" data-image="' + image.fullsize + '" data-zoom-image="' + image.zoomin + '"><div class="product-page__thumbnail-image" style="background-image:url(' + image.thumb + ');"></div></a>');
        }
      }
    }
  },

  /**
   * Refresh the sku second description
   */
  refreshSkuSecondDescription: function refreshSkuSecondDescription(secondDescription) {

    var more = "<h3>" + Translation.find('more', 'title') + "</h3>";

    if (typeof secondDescription !== "undefined") {
      $('#product-file-attachment-and-data').html(more + secondDescription);
    } else {
      $('#product-file-attachment-and-data').html('');
    }
  },

  /**
   * Refresh the sku attachment (depending on second description too)
   */
  refreshSkuAttachment: function refreshSkuAttachment(secondDescription, attachment) {

    var more = "<h3>" + Translation.find('more', 'title') + "</h3>";

    if (typeof attachment !== "undefined") {
      if (typeof secondDescription !== "undefined") {
        $('#product-file-attachment-and-data').html(more + secondDescription);
      }
      $('#product-file-attachment-and-data').append('<br /><a class="btn btn-default" target="_blank" href="' + attachment + '">PDF Documentation</a>');
    }
  }

};

module.exports = ProductsShow;
});

require.register("javascripts/controllers/shopkeeper/products/skus.js", function(exports, require, module) {
'use strict';

var Translation = require('javascripts/lib/translation');

/**
 * ProductNewSku Class
 */
var ProductNewSku = {

  /**
   * Initializer
   */
  init: function init() {

    /**
     * TODO: THIS SEEMS TO BE HIGHLY DEPRECATED BUT WE SHOULD MAKE SURE IT IS BEFORZ TO REMOVE
     */

    $('select.sku-variants-options').multiselect({
      nonSelectedText: Translation.find('non_selected_text', 'multiselect'),
      nSelectedText: Translation.find('n_selected_text', 'multiselect'),
      numberDisplayed: 3,
      maxHeight: 400,
      onChange: function onChange(option, checked) {
        var v = $('.sku-variants-options');
        if (v.val()) {
          v.next().removeClass('invalidBorderClass');
        } else {
          v.next().addClass('invalidBorderClass');
        }
      }
    });

    $('#edit_product_detail_form_btn').click(function () {
      var v = $('select.sku-variants-options');

      if (v.val() == null) {
        v.next().addClass('invalidBorderClass');
        return false;
      }

      if ($('img.img-responsive[src=""]').length >= 4) {
        $('.fileUpload:first').addClass('invalidBorderClass');
        return false;
      }

      $('input.img-file-upload').click(function () {
        if ($('img.img-responsive[src=""]').length > 0) {
          $('.fileUpload').removeClass('invalidBorderClass');
        }
      });

      return true;
    });
  }

};

module.exports = ProductNewSku;
});

require.register("javascripts/controllers/shopkeeper/products/skus/index.js", function(exports, require, module) {
'use strict';

var Translation = require('javascripts/lib/translation');

/**
 * ProductsShowSkus Class
 */
var ProductsShowSkus = {

  /**
   * Initializer
   */
  init: function init() {

    if ($('select.sku-variants-options').length > 0) {

      $('select.sku-variants-options').multiselect({
        nonSelectedText: Translation.find('non_selected_text', 'multiselect'),
        nSelectedText: Translation.find('n_selected_text', 'multiselect'),
        numberDisplayed: 3,
        maxHeight: 400
      }).multiselect('disable');
    }
  }

};

module.exports = ProductsShowSkus;
});

require.register("javascripts/controllers/shopkeeper/products/variants.js", function(exports, require, module) {
"use strict";

/**
 * ProductsVariants Class
 */
var ProductsVariants = {

  /**
   * Initializer
   */
  init: function init() {

    /**
     * Since the system is cloned on the admin we try
     * to limit the code duplication by abstracting into a library
     */
    var Variants = require("javascripts/lib/variants");
    Variants.setup();
  }

};

module.exports = ProductsVariants;
});

require.register("javascripts/controllers/shopkeeper/wirecards/apply.js", function(exports, require, module) {
"use strict";

/**
 * Apply Wirecard Class
 */
var ShopkeeperWirecardApply = {

  /**
   * Initializer
   */
  init: function init() {

    this.postShopDetails();
  },

  /**
   * Post shop details to the `form_url`
   */
  postShopDetails: function postShopDetails() {

    var Casing = require("javascripts/lib/casing");
    var PostForm = require("javascripts/lib/post_form.js");

    var shopDetails = $("#shop-details").data();
    var parsedShopDetails = Casing.objectToUnderscoreCase(shopDetails);

    PostForm.send(parsedShopDetails, parsedShopDetails['form_url']);
  }

};

module.exports = ShopkeeperWirecardApply;
});

require.register("javascripts/initialize.js", function(exports, require, module) {
"use strict";

$(document).ready(function () {

  /**
   * Controllers loader by Loschcode
   * Damn simple class loader.
   */
  var routes = $("#js-routes").data();
  var info = $("#js-info").data();
  var starters = require("javascripts/starters");

  /**
   * Disable console.log for production and tests (poltergeist)
   */
  if (info.environment == "production" || info.environment == "test") {
    if (typeof window.console != "undefined") {
      window.console = {};
      window.console.log = function () {};
      window.console.info = function () {};
      window.console.warn = function () {};
      window.console.error = function () {};
    }
  }

  try {

    var Casing = require("javascripts/lib/casing");

    for (var idx in starters) {

      console.info('Loading starter : ' + starters[idx]);

      var formatted_starter = Casing.underscoreCase(starters[idx]).replace('-', '_');
      var _obj = require("javascripts/starters/" + formatted_starter);
      _obj.init();
    }
  } catch (err) {

    console.error("Unable to initialize #js-starters (" + err + ")");
    return;
  }

  try {
    var meta_obj = require("javascripts/controllers/" + routes.controller);
    console.info("Loading controller " + routes.controller);
    meta_obj.init();
  } catch (err) {
    console.warn("Unable to initialize #js-routes `" + routes.controller + "` (" + err + ")");
  }

  try {
    var obj = require("javascripts/controllers/" + routes.controller + "/" + routes.action);
    console.info("Loading controller-action " + routes.controller + "/" + routes.action);
  } catch (err) {
    console.warn("Unable to initialize #js-routes `" + routes.controller + "`.`" + routes.action + "` (" + err + ")");
    return;
  }

  /**
   * Initialization
   */
  obj.init();
});
});

require.register("javascripts/lib/casing.js", function(exports, require, module) {
"use strict";

/**
 * Casing Class
 */
var Casing = {

  /**
   * CamelCase to underscored case
   */
  underscoreCase: function underscoreCase(string) {
    return string.replace(/(?:^|\.?)([A-Z])/g, function (x, y) {
      return "_" + y.toLowerCase();
    }).replace(/^_/, "").replace('-', '_');
  },

  /**
   * Undescored to CamelCase
   */
  camelCase: function camelCase(string) {
    return string.replace(/(\-[a-z])/g, function ($1) {
      return $1.toUpperCase().replace('-', '');
    });
  },

  /**
   * Convert an object to underscore case
   */
  objectToUnderscoreCase: function objectToUnderscoreCase(obj) {

    var parsed = {};
    for (var key in obj) {

      var new_key = this.underscoreCase(key);
      parsed[new_key] = obj[key];
    }

    return parsed;
  }

};

module.exports = Casing;
});

require.register("javascripts/lib/content_preloader.js", function(exports, require, module) {
"use strict";

/**
 * ContentPreloader Class
 */
var ContentPreloader = {

  /**
   * Preload some content inside the system
   * @param  {String} image new image source
   * @param  {String} loader_selector loader to display
   * @return {void}
   */
  process: function process(selected_attr, loader_selector) {

    selected_attr.load(function () {
      $(loader_selector).hide();
      $(this).show();
    }).before(function () {
      $(loader_selector).show();
      $(this).hide();
    });
  }

};

module.exports = ContentPreloader;
});

require.register("javascripts/lib/foreign/datepicker-de.js", function(exports, require, module) {
"use strict";

/* German initialisation for the jQuery UI date picker plugin. */
/* Written by Milian Wolff (mail@milianw.de). */
(function (factory) {
  if (typeof define === "function" && define.amd) {

    // AMD. Register as an anonymous module.
    define(["../widgets/datepicker"], factory);
  } else {

    // Browser globals
    factory(jQuery.datepicker);
  }
})(function (datepicker) {

  datepicker.regional.de = {
    closeText: "Schließen",
    prevText: "&#x3C;Zurück",
    nextText: "Vor&#x3E;",
    currentText: "Heute",
    monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"],
    monthNamesShort: ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"],
    dayNames: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"],
    dayNamesShort: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
    dayNamesMin: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
    weekHeader: "KW",
    dateFormat: "dd.mm.yy",
    firstDay: 1,
    isRTL: false,
    showMonthAfterYear: false,
    yearSuffix: "" };
  datepicker.setDefaults(datepicker.regional.de);

  return datepicker.regional.de;
});
});

require.register("javascripts/lib/foreign/datepicker-zh-CN.js", function(exports, require, module) {
"use strict";

/* Chinese initialisation for the jQuery UI date picker plugin. */
/* Written by Cloudream (cloudream@gmail.com). */
(function (factory) {
  if (typeof define === "function" && define.amd) {

    // AMD. Register as an anonymous module.
    define(["../widgets/datepicker"], factory);
  } else {

    // Browser globals
    factory(jQuery.datepicker);
  }
})(function (datepicker) {

  datepicker.regional["zh-CN"] = {
    closeText: "关闭",
    prevText: "&#x3C;上月",
    nextText: "下月&#x3E;",
    currentText: "今天",
    monthNames: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
    monthNamesShort: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
    dayNames: ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"],
    dayNamesShort: ["周日", "周一", "周二", "周三", "周四", "周五", "周六"],
    dayNamesMin: ["日", "一", "二", "三", "四", "五", "六"],
    weekHeader: "周",
    dateFormat: "yy-mm-dd",
    firstDay: 1,
    isRTL: false,
    showMonthAfterYear: true,
    yearSuffix: "年" };
  datepicker.setDefaults(datepicker.regional["zh-CN"]);

  return datepicker.regional["zh-CN"];
});
});

require.register("javascripts/lib/messages.js", function(exports, require, module) {
'use strict';

/**
 * Messages Class
 */
var Messages = { // NOTE : We should use a template system to handle the HTML here

  makeError: function makeError(error) {

    $("#messages-container").html('<div id="message-error" class="col-xs-10 col-xs-push-1 col-md-4 col-md-push-4 col-md-pull-4 message message__error +centered">' + error + '</div>');
    Messages.activateHide('#message-error', 3000);
  },

  makeSuccess: function makeSuccess(success) {

    $("#messages-container").html('<div id="message-success" class="col-xs-10 col-xs-push-1 col-md-4 col-md-push-4 col-md-pull-4 message message__success +centered">' + success + '</div>');
    Messages.activateHide('#message-success', 4000);
  },

  activateHide: function activateHide(el, time) {

    setTimeout(function () {
      $(el).fadeOut(function () {
        $(document).trigger('message:hidden'); // To replace footer
      });
    }, time);
  }

};

module.exports = Messages;
});

require.register("javascripts/lib/post_form.js", function(exports, require, module) {
"use strict";

/**
 * PostForm Class
 */
var PostForm = {

  /**
   * Generate and create a form
   */
  send: function send(params, path, target, method) {

    var method = method || "POST";
    var path = path || "";
    var target = target || "";

    var form = document.createElement("form");
    form.setAttribute("method", method);
    form.setAttribute("action", path);
    form.setAttribute("target", target);

    for (var key in params) {

      if (params.hasOwnProperty(key)) {

        var f = document.createElement("input");
        f.setAttribute("type", "hidden");
        f.setAttribute("name", key);
        f.setAttribute("value", params[key]);
        form.appendChild(f);
      }
    }

    document.body.appendChild(form); // <- JS way
    // $('body').append(form); // <- jQuery way
    //console.log(form);
    form.submit();
  }

};

module.exports = PostForm;
});

require.register("javascripts/lib/preloader.js", function(exports, require, module) {
"use strict";

/**
* Preloader Class
*/
var Preloader = {

  /**
  * Check an element and hide it until the trigger is loaded itself
  * Show a loder `.js-loader` if possible
  */
  dispatchLoader: function dispatchLoader(element, loader_selector, trigger) {

    $(loader_selector).show();
    $(element).hide();

    $(trigger).load(function () {
      $(loader_selector).hide();
      $(element).show();
    });
  }

};

module.exports = Preloader;
});

require.register("javascripts/lib/skus.js", function(exports, require, module) {
'use strict';

/**
 * Skus Class
 */
var Skus = {

  setup: function setup() {

    this.handleMultiSelect();
    this.handleForm();
  },

  /**
   * We turn the multi-select of the sku dashboard management into a readable checkbox select
   * @return {void}
   */
  handleMultiSelect: function handleMultiSelect() {

    var Translation = require('javascripts/lib/translation');

    $('select.sku-variants-options').multiselect({
      nonSelectedText: Translation.find('non_selected_text', 'multiselect'),
      nSelectedText: Translation.find('n_selected_text', 'multiselect'),
      numberDisplayed: 3,
      maxHeight: 400,
      onChange: function onChange(option, checked) {
        var v = $('.sku-variants-options');
        if (v.val()) {
          v.next().removeClass('invalidBorderClass');
        } else {
          v.next().addClass('invalidBorderClass');
        }
      }
    });
  },

  /**
   * This seems to handle the images warning on the skus form for shopkeeper and admin
   * NOTE : i didn't refactor this, it should be made cleaner and check the use.
   */
  handleForm: function handleForm() {

    $('#edit_product_detail_form_btn').click(function () {
      var v = $('select.sku-variants-options');

      if (v.val() == null) {
        v.next().addClass('invalidBorderClass');
        return false;
      }

      if ($('img.img-responsive[src=""]').length >= 4) {
        $('.fileUpload:first').addClass('invalidBorderClass');
        return false;
      }

      $('input.img-file-upload').click(function () {
        if ($('img.img-responsive[src=""]').length > 0) {
          $('.fileUpload').removeClass('invalidBorderClass');
        }
      });

      return true;
    });
  }

};

module.exports = Skus;
});

require.register("javascripts/lib/translation.js", function(exports, require, module) {
"use strict";

/**
 * Translation Class
 */
var Translation = {

  find: function find(translationSlug, translationScope) {

    var selector = ".js-translation[data-slug='" + translationSlug + "'][data-scope='" + translationScope + "']";
    if ($(selector).length > 0) {
      return $(selector).data('content');
    } else {
      console.error("Translation not found : `" + translationScope + "`.`" + translationSlug + "`");
      return '';
    }
  },

  /**
  * Find a translation and return the string from AJAX with callbacks
  */
  findAsync: function findAsync(translationSlug, translationScope, callback) {

    var TranslationModel = require("javascripts/models/translation");

    TranslationModel.show(translationSlug, translationScope, function (res) {

      if (res.success === false) {
        console.error("Translation not found `" + translationSlug + "` (" + res.error + ")");
      } else {
        callback(res.translation);
      }
    });
  }

};

module.exports = Translation;
});

require.register("javascripts/lib/url_process.js", function(exports, require, module) {
'use strict';

/**
 * UrlProcess Class
 */
var UrlProcess = {

    insertParam: function insertParam(key, value) {

        key = encodeURI(key);value = encodeURI(value);

        var kvp = document.location.search.substr(1).split('&');

        var i = kvp.length;var x;while (i--) {
            x = kvp[i].split('=');

            if (x[0] == key) {
                x[1] = value;
                kvp[i] = x.join('=');
                break;
            }
        }

        if (i < 0) {
            kvp[kvp.length] = [key, value].join('=');
        }

        //this will reload the page, it's likely better to store this until finished
        document.location.search = kvp.join('&');
    }

};

module.exports = UrlProcess;
});

require.register("javascripts/lib/variants.js", function(exports, require, module) {
'use strict';

/**
 * Variants Class
 */
var Variants = {

  setup: function setup() {

    this.addOptionHandler();
    this.removeOptionHandler();

    this.addVariantHandler();
    this.removeVariantHandler();
  },

  addVariantHandler: function addVariantHandler() {

    $('#add-variant').on('click', function (e) {

      e.preventDefault();
      var target = $('.js-temporary-variant.hidden:first');
      console.log(target);
      target.removeClass('hidden');
    });
  },

  removeVariantHandler: function removeVariantHandler() {

    $('.js-remove-variant').on('click', function (e) {

      e.preventDefault();
      var container = $(this).closest('.js-temporary-variant');
      var input_target = container.find('input');
      input_target.val('');
      container.addClass('hidden');
    });
  },

  /**
   * We add an option (aka suboption in some cases) to the variant
   * It will just show a field which was previously hidden
   * NOTE : everything is managed by rails itself beforehand
   * to make it flexible in the front-end side
   */
  addOptionHandler: function addOptionHandler() {

    $('.js-add-option').on('click', function (e) {

      e.preventDefault();
      var target = $(this).closest('.variant-box').find('.js-temporary-option.hidden:first');
      target.removeClass('hidden');
    });
  },

  /**
   * Set the value of the field to empty
   * and hide it from the display
   */
  removeOptionHandler: function removeOptionHandler() {

    $('.js-remove-option').on('click', function (e) {

      e.preventDefault();
      var container = $(this).closest('.js-temporary-option');
      var input_target = container.find('input');
      input_target.val('');
      container.addClass('hidden');
    });
  }

};

module.exports = Variants;
});

require.register("javascripts/models.js", function(exports, require, module) {
"use strict";

/**
 * Models Class
 */
var Models = [

  // Not currently in use (please load each model on a case per case basis)
  //
];

module.exports = Models;
});

require.register("javascripts/models/cart.js", function(exports, require, module) {
"use strict";

/**
 * Cart Class
 */
var Cart = {

  /**
   * Get the total number of products within the cart
   */
  total: function total(callback) {

    // NOTE : condition race made it impossible to build
    // I passed 2 full days on this problem
    // Good luck.
    // - Laurent
    $.ajax({
      method: "GET",
      url: "/api/guest/cart/total",
      data: {}

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  }

};

module.exports = Cart;
});

require.register("javascripts/models/duty_category.js", function(exports, require, module) {
"use strict";

/**
 * Duty Category Class
 */
var DutyCategory = {

  /**
   * Check if user is auth or not via API call
   */
  find: function find(dutyCategoryId, callback) {

    $.ajax({
      method: "GET",
      url: "/api/admin/duty_categories/" + dutyCategoryId,
      data: {}

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  }

};

module.exports = DutyCategory;
});

require.register("javascripts/models/navigation_model.js", function(exports, require, module) {
"use strict";

/**
 * NavigationModel Class
 */
var NavigationModel = {

  /**
   * Check if user is auth or not via API call
   */
  setLocation: function setLocation(location, callback) {

    $.ajax({
      method: "PATCH",
      url: "/api/guest/navigation/",
      data: { "location": location }

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  }

};

module.exports = NavigationModel;
});

require.register("javascripts/models/order_item.js", function(exports, require, module) {
"use strict";

/**
 * OrderItem Class
 */
var OrderItem = {

  /**
   * Check if user is auth or not via API call
   */
  setQuantity: function setQuantity(orderItemId, quantity, callback) {

    $.ajax({
      method: "PATCH",
      url: "/api/guest/order_items/" + orderItemId,
      data: { "quantity": quantity }

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  },

  addProduct: function addProduct(productId, quantity, optionIds, callback) {
    $.ajax({
      method: "POST",
      url: "/api/guest/order_items",
      data: { product_id: productId, quantity: quantity, option_ids: optionIds }

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  }

};

module.exports = OrderItem;
});

require.register("javascripts/models/product.js", function(exports, require, module) {
"use strict";

/**
 * Product Class
 */
var Product = {

  /**
   * Like a product
   */
  like: function like(productId, callback) {

    $.ajax({
      method: "PUT",
      url: "/api/customer/favorites/" + productId,
      data: {}

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  },

  /**
   * Unlike a product
   */
  unlike: function unlike(productId, callback) {

    $.ajax({
      method: "DELETE",
      url: "/api/customer/favorites/" + productId,
      data: {}

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  }

};

module.exports = Product;
});

require.register("javascripts/models/product_sku.js", function(exports, require, module) {
'use strict';

/**
 * ProductSku Class
 */
var ProductSku = {

  /**
   * Get the ProductSku details
   */
  show: function show(productId, optionIds, callback) {

    $.ajax({

      method: "GET",
      url: '/api/guest/products/' + productId + '/skus/0', // 0 is to match with the norm ... hopefully when we go away from mongo there's no such things
      data: { option_ids: optionIds }

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  },

  /**
   * Get all the Skus from the Product
   */
  all: function all(productId, callback) {

    $.ajax({

      method: "GET",
      url: '/api/guest/products/' + productId + '/skus',
      data: {}

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  }

};

module.exports = ProductSku;
});

require.register("javascripts/models/translation.js", function(exports, require, module) {
"use strict";

/**
 * Translations Class
 */
var Translations = {

  /**
   * Get the Translations details
   */
  show: function show(translationSlug, translationScope, callback) {

    $.ajax({

      method: "GET",
      url: '/api/guest/translations/0',
      data: { translation_slug: translationSlug, translation_scope: translationScope }

    }).done(function (res) {

      callback(res);
    }).error(function (err) {

      callback({ success: false, error: err.responseJSON.error });
    });
  }

};

module.exports = Translations;
});

require.register("javascripts/services/refresh_total_products.js", function(exports, require, module) {
'use strict';

/**
 * RefreshTotalProducts Class
 */
var RefreshTotalProducts = {

  /**
   * Refresh it
   */
  perform: function perform() {

    var Cart = require('javascripts/models/cart');
    Cart.total(function (res) {
      $(".js-total-products").html(res.datas);
      RefreshTotalProducts.resolveHiding(res.datas);
    });
  },

  resolveHiding: function resolveHiding(total) {
    if (total > 0) {
      $('.js-total-products').removeClass('+hidden');
    } else {
      $('.js-total-products').addClass('+hidden');
    }
  }

};

module.exports = RefreshTotalProducts;
});

require.register("javascripts/starters.js", function(exports, require, module) {
'use strict';

/**
 * Starters Class
 */
var Starters = ['auto_resize', 'back_to_top', 'bootstrap', 'china_city', 'datepicker', 'editable_fields', 'footer', 'input_validation', 'images_handler', 'lazy_loader', 'left_menu', 'links_behaviour', 'messages', 'mobile_menu', 'navigation', 'product_favorite', 'product_form', 'products_list', 'qrcode', 'refresh_time', 'responsive', 'search', 'sku_form', 'sweet_alert', 'tooltipster', 'total_products'];

module.exports = Starters;
});

require.register("javascripts/starters/auto_resize.js", function(exports, require, module) {
'use strict';

/**
 * AutoResize Class
 */
var AutoResize = {

  /**
   * Initializer
   */
  init: function init() {

    this.setupAutoResize();
  },

  setupAutoResize: function setupAutoResize() {

    $('textarea').textareaAutoSize();
  }
};

module.exports = AutoResize;
});

require.register("javascripts/starters/back_to_top.js", function(exports, require, module) {
'use strict';

/**
 * BackToTop Class
 */
var BackToTop = {

  /**
  * Initializer
  */
  init: function init() {

    this.setupBackToTop();
  },

  /**
   * Back to top button system
   * NOTE : This was taken from the Internet
   * Don't hesitate to refactor if needed
   */
  setupBackToTop: function setupBackToTop() {

    $(function () {
      $.scrollUp({
        scrollName: 'scrollUp', // Element ID
        scrollDistance: 300, // Distance from top/bottom before showing element (px)
        scrollFrom: 'top', // 'top' or 'bottom'
        scrollSpeed: 300, // Speed back to top (ms)
        easingType: 'linear', // Scroll to top easing (see http://easings.net/)
        animation: 'fade', // Fade, slide, none
        animationSpeed: 200, // Animation speed (ms)
        scrollTrigger: false, // Set a custom triggering element. Can be an HTML string or jQuery object
        scrollTarget: false, // Set a custom target element for scrolling to. Can be element or number
        scrollText: '<i class="fa fa-caret-up"></i>', // Text for element, can contain HTML
        scrollTitle: false, // Set a custom <a> title if required.
        scrollImg: false, // Set true to use image
        activeOverlay: false, // Set CSS color to display scrollUp active point, e.g '#00FFFF'
        zIndex: 2147483647 // Z-Index for the overlay
      });
    });
  }

};

module.exports = BackToTop;
});

require.register("javascripts/starters/bootstrap.js", function(exports, require, module) {
"use strict";

/**
 * Bootstrap Class
 */
var Bootstrap = {

  /**
   * Initializer
   */
  init: function init() {

    this.startPopover();
    this.startTooltip();
  },

  /**
   * 
   */
  startPopover: function startPopover() {

    $("a[rel~=popover], .has-popover").popover();
  },

  startTooltip: function startTooltip() {

    $("a[rel~=tooltip], .has-tooltip").tooltip();
  }

};

module.exports = Bootstrap;
});

require.register("javascripts/starters/china_city.js", function(exports, require, module) {
'use strict';

/**
 * ChinaCity Class
 */
var ChinaCity = {

    ajax_url: "/api/guest/china_city/",

    /**
     * Initializer
     */
    init: function init() {

        this.startChinaCity();
    },

    /**
     * Get the china cities
     * NOTE : this was taken from the old system and is very very disgusting.
     * Don't hesitate to refactor all this shit when you get the time.
     */
    startChinaCity: function startChinaCity() {

        $.fn.china_city = function () {
            return this.each(function () {
                var selects;
                selects = $(this).find('.city-select');
                return selects.change(function () {
                    console.log('what');
                    var $this, next_selects;
                    $this = $(this);
                    next_selects = selects.slice(selects.index(this) + 1);
                    $("option:gt(0)", next_selects).remove();
                    if (next_selects.first()[0] && $this.val() && !$this.val().match(/--.*--/)) {
                        return $.get(ChinaCity.ajax_url + $(this).val(), function (data) {
                            var i, len, option;
                            if (data.data != null) {
                                data = data.data;
                            }
                            for (i = 0, len = data.length; i < len; i++) {
                                option = data[i];
                                next_selects.first()[0].options.add(new Option(option[0], option[1]));
                            }
                            return next_selects.trigger('china_city:load_data_completed');
                        });
                    }
                });
            });
        };

        $(document).ready(function () {
            $('.city-group').china_city();
        });
    }

};

module.exports = ChinaCity;
});

require.register("javascripts/starters/datepicker.js", function(exports, require, module) {
'use strict';

/**
 * Datepicker Class
 */
var Datepicker = {

  /**
   * Initializer
   */
  init: function init() {

    if ($('#js-show-datepicker').length > 0) {

      var showDatepicker = $('#js-show-datepicker').data();
      var language = showDatepicker.language ? showDatepicker.language : 'de';

      if (language == 'de') {
        require("javascripts/lib/foreign/datepicker-de.js");
      } else {
        require("javascripts/lib/foreign/datepicker-zh-CN.js");
      }

      $("#datepicker").datepicker({
        changeMonth: true,
        changeYear: true,
        yearRange: '1945:' + new Date().getFullYear(),
        dateFormat: "yy-mm-dd"
      });
    }
  }

};

module.exports = Datepicker;
});

require.register("javascripts/starters/editable_fields.js", function(exports, require, module) {
'use strict';

/**
 * EditableFields Class
 * Will make the edit fields appear and the text disappear
 * It's used in the order edit for admin (for example)
 * This is a very small system, not ambitious at all
 * Keep it this way or use a real plugin.
 */
var EditableFields = {

  /**
   * Initializer
   */
  init: function init() {

    EditableFields.hideAllEditable();

    $('.js-editable-click').on('click', function (e) {
      e.preventDefault();
      EditableFields.showEditable(this);
    });
  },

  hideAllEditable: function hideAllEditable(element) {
    $('.js-editable-text').show();
    $('.js-editable-field').hide();
    $('.js-editable-click').show();
    $('.js-editable-submit').hide();
  },

  hideEditable: function hideEditable(element) {
    $(element).parent().find('.js-editable-text').show();
    $(element).parent().find('.js-editable-field').hide();
    $(element).parent().find('.js-editable-click').show();
    $(element).parent().find('.js-editable-submit').hide();
  },

  showEditable: function showEditable(element) {
    $(element).parent().find('.js-editable-text').hide();
    $(element).parent().find('.js-editable-field').show();
    $(element).parent().find('.js-editable-click').hide();
    $(element).parent().find('.js-editable-submit').show();
  }

};

module.exports = EditableFields;
});

require.register("javascripts/starters/footer.js", function(exports, require, module) {
'use strict';

/**
 * Footer Class
 */
var Footer = {

  /**
   * Initializer
   */
  init: function init() {

    this.stickyFooter();
  },

  /**
   * Put the footer on the bottom of the page
   */
  stickyFooter: function stickyFooter() {

    var self = this;

    if ($('.js-footer-stick').length > 0) {

      Footer.processStickyFooter();

      $(document).on('message:hidden', function () {
        Footer.processStickyFooter();
      });

      $(window).resize(function () {
        Footer.processStickyFooter();
      });
    }
  },

  processStickyFooter: function processStickyFooter() {

    var docHeight, footerHeight, footerTop;

    $('.js-footer-stick').css('margin-top', 0);

    var docHeight = $(window).height();
    var footerHeight = $('.js-footer-stick').height();
    var headerHeight = $('.navbar-fixed-top').first().height();
    var footerTop = $('.js-footer-stick').position().top + footerHeight;

    if (footerTop < docHeight) {
      $('.js-footer-stick').css('margin-top', docHeight + headerHeight * 1.30 - footerTop + 'px');
    }
  }

};

module.exports = Footer;
});

require.register("javascripts/starters/images_handler.js", function(exports, require, module) {
"use strict";

/**
* ImagesHandler Class
*/
var ImagesHandler = {

  elements: {
    image: ".js-file-upload"
  },

  /**
  * Initializer
  */
  init: function init() {

    this.validateImageFile();
    this.imageLiveRefresh();
  },

  /**
  * Validate the image itself when it's changed
  * @return {void}
  */
  validateImageFile: function validateImageFile() {

    $(ImagesHandler.elements.image).on('change', function () {

      var Messages = require("javascripts/lib/messages");
      var Translation = require("javascripts/lib/translation");
      var inputFile = this;

      var maxExceededMessage = Translation.find('max_exceeded_message', 'image_upload');
      var extErrorMessage = Translation.find('ext_error_message', 'image_upload');
      var allowedExtension = ["jpg", "JPG", "jpeg", "JPEG", "png", "PNG"];
      var extName;
      var maxFileSize = 1048576 * 3; // 3MB
      var sizeExceeded = false;
      var extError = false;

      $.each(inputFile.files, function () {
        if (this.size && maxFileSize && this.size > maxFileSize) {
          sizeExceeded = true;
        };
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {
          extError = true;
        };
      });

      if (sizeExceeded) {
        Messages.makeError(maxExceededMessage);
        $(inputFile).val('');
      };

      if (extError) {
        Messages.makeError(extErrorMessage);
        $(inputFile).val('');
      };
    });
  },

  /**
  * This system is basically live refreshing the images when you select one from your browser
  * It's mainly used by the shopkeepers
  * @return {void}
  */
  imageLiveRefresh: function imageLiveRefresh() {

    if ($(ImagesHandler.elements.image).length > 0) {

      $(ImagesHandler.elements.image).each(function () {

        var fileElement = $(this);

        $(this).change(function (event) {
          var input = $(event.currentTarget);
          var file = input[0].files[0];
          var reader = new FileReader();
          reader.onload = function (e) {
            var image_base64 = e.target.result;

            var image_div = fileElement.attr('image_selector');
            $(image_div).attr("src", image_base64);

            // we show the update
            var add_link = fileElement.attr('image_selector') + '_add';
            $(add_link).removeClass('hidden');
          };
          reader.readAsDataURL(file);
        });
      });
    }
  }

};

module.exports = ImagesHandler;
});

require.register("javascripts/starters/input_validation.js", function(exports, require, module) {
'use strict';

/**
* InputValidation Class
*/
var InputValidation = {

  /**
  * Initializer
  */
  init: function init() {

    this.restrictToChinese();
  },

  /**
   * USE : just add data-error to an input to have the custom error show up
   */
  restrictToChinese: function restrictToChinese() {

    $("input").on('invalid', function (e) {
      if (typeof $(this).data('error') != "undefined") {
        this.setCustomValidity($(this).data('error'));
      }
    });

    $("input").on('keyup', function (e) {
      this.setCustomValidity("");
    });
  }

};

module.exports = InputValidation;
});

require.register("javascripts/starters/lazy_loader.js", function(exports, require, module) {
"use strict";

/**
 * LazyLoader Class
 */
var LazyLoader = {

  /**
   * Initializer
   */
  init: function init() {

    this.startLazyLoader();
  },

  /**
   *
   */
  startLazyLoader: function startLazyLoader() {

    $("div.lazy").lazyload({
      effect: "fadeIn"
    });
  }

};

module.exports = LazyLoader;
});

require.register("javascripts/starters/left_menu.js", function(exports, require, module) {
'use strict';

/**
 * LeftMenu Class
 */
var LeftMenu = {

  /**
   * Initializer
   */
  init: function init() {

    this.startLeftMenu();
  },

  /**
   *
   */
  startLeftMenu: function startLeftMenu() {

    $('select.nice').niceSelect();
    $('.overlay').on('click', function (e) {
      $('#mobile-menu-button').trigger('click');
    });

    // NOTE : no idea what this is, i think it doesn't exist anymore
    // - Laurent 26/01/2017
    // $('#left_menu > ul > li > a').click(function() {
    //     $('#left_menu li').removeClass('active');
    //     $(this).closest('li').addClass('active');
    //     var checkElement = $(this).next();
    //     if((checkElement.is('ul')) && (checkElement.is(':visible'))) {
    //         $(this).closest('li').removeClass('active');
    //         checkElement.slideUp('normal');
    //     }
    //     if((checkElement.is('ul')) && (!checkElement.is(':visible'))) {
    //         $('#left_menu ul ul:visible').slideUp('normal');
    //         checkElement.slideDown('normal');
    //     }
    //     if($(this).closest('li').find('ul').children().length == 0) {
    //         return true;
    //     } else {
    //         return false;
    //     }
    // });
  }

};

module.exports = LeftMenu;
});

require.register("javascripts/starters/links_behaviour.js", function(exports, require, module) {
'use strict';

/**
 * LinkBehaviour Class
 */
var LinkBehaviour = {

  /**
   * Initializer
   */
  init: function init() {

    this.setupSubmitForm();
  },

  /**
   * If we use the data-submit-form it will force submit with a simple link
   */
  setupSubmitForm: function setupSubmitForm() {

    $(document).on('click', '[data-form="submit"]', function (e) {
      e.preventDefault();
      $(this).closest('form').submit();
    });
  }

};

module.exports = LinkBehaviour;
});

require.register("javascripts/starters/messages.js", function(exports, require, module) {
"use strict";

/**
 * Messages Class
 */
var Messages = {

  /**
   * Initializer
   */
  init: function init() {

    this.hideMessages();
  },

  /**
   *
   */
  hideMessages: function hideMessages() {

    var Messages = require("javascripts/lib/messages");

    if ($("#message-error").length > 0) {
      Messages.activateHide('#message-error', 5000);
    }

    if ($("#message-success").length > 0) {
      Messages.activateHide('#message-success', 6000);
    }
  }

};

module.exports = Messages;
});

require.register("javascripts/starters/mobile_menu.js", function(exports, require, module) {
'use strict';

/**
 * MobileMenu Class
 */
var MobileMenu = {

    /**
     * Initializer
     */
    init: function init() {

        this.startMobileMenu();
    },

    /**
     *
     */
    startMobileMenu: function startMobileMenu() {

        this.manageFade();
    },

    manageFade: function manageFade() {

        $('.navmenu').on('show.bs.offcanvas', function () {
            $('.canvas').addClass('sliding');
        }).on('shown.bs.offcanvas', function () {}).on('hide.bs.offcanvas', function () {
            $('.canvas').removeClass('sliding');
        }).on('hidden.bs.offcanvas', function () {});
    }

};

module.exports = MobileMenu;
});

require.register("javascripts/starters/navigation.js", function(exports, require, module) {
"use strict";

/**
 * Navigation Class
 */
var Navigation = {

  /**
   * Initializer
   */
  init: function init() {

    this.storeNavigation();
  },

  /**
   * We send the navigation to the back-end
   */
  storeNavigation: function storeNavigation() {

    var NavigationModel = require("javascripts/models/navigation_model");
    NavigationModel.setLocation(window.location.href, function (res) {
      // Nothing yet
    });
  }

};

module.exports = Navigation;
});

require.register("javascripts/starters/product_favorite.js", function(exports, require, module) {
"use strict";

var Translation = require('javascripts/lib/translation');

/**
 * ProductFavorite Class
 */
var ProductFavorite = {

  /**
   * Initializer
   */
  init: function init() {

    this.manageHeartClick();
  },

  /**
   * When the heart is clicked
   */
  manageHeartClick: function manageHeartClick() {

    var self = this;

    $(".js-heart-click").on("click", function (e) {

      e.preventDefault();

      var productId = $(this).attr('data-product-id');
      var favorite = $(this).attr('data-favorite'); // Should be converted

      if (favorite == '1') {

        // We remove the favorite front data
        ProductFavorite.doUnlikeDisplay(this);
        ProductFavorite.doUnlike(productId, function (res) {

          var favoritesCount = res.favorites.length;
          $('#total-likes').html(favoritesCount);
        });
      } else {

        // We change the style before the callback for speed reason
        ProductFavorite.doLikeDisplay(this);
        ProductFavorite.doLike(productId, function (res) {

          var favoritesCount = res.favorites.length;
          $('#total-likes').html(favoritesCount);
        });
      }
    });
  },

  doLike: function doLike(productId, callback) {

    var Product = require("javascripts/models/product");
    var Messages = require("javascripts/lib/messages");

    Product.like(productId, function (res) {

      if (res.success === false) {

        Messages.makeError(res.error);
      } else {

        callback(res);
      }
    });
  },

  doLikeDisplay: function doLikeDisplay(el) {

    $(el).find('i').addClass('+pink');
    $(el).find('i').removeClass('+grey');
    $(el).attr('data-favorite', '1');
    $(el).find('span').html(Translation.find('remove', 'favorites'));
  },

  doUnlike: function doUnlike(productId, callback) {

    var Product = require("javascripts/models/product");
    var Messages = require("javascripts/lib/messages");

    Product.unlike(productId, function (res) {

      if (res.success === false) {

        Messages.makeError(res.error);
      } else {

        callback(res);
      }
    });
  },

  doUnlikeDisplay: function doUnlikeDisplay(el) {

    $(el).find('i').addClass('+grey');
    $(el).find('i').removeClass('+pink');
    $(el).attr('data-favorite', '0');
    $(el).find('span').html(Translation.find('add', 'favorites'));
  }
};

module.exports = ProductFavorite;
});

require.register("javascripts/starters/product_form.js", function(exports, require, module) {
"use strict";

var Translation = require('javascripts/lib/translation');

/**
 * ProductForm Class
 */
var ProductForm = {

  /**
   * Initializer
   */
  init: function init() {

    this.manageShopkeeperProductForm();
  },

  manageShopkeeperProductForm: function manageShopkeeperProductForm() {

    if ($("#js-product-form").length > 0) {

      var productForm = $("#js-product-form").data();
      var productId = productForm.productId;

      $('select.duty-categories').multiselect({
        nonSelectedText: Translation.find('non_selected_text', 'multiselect'),
        nSelectedText: Translation.find('n_selected_text', 'multiselect'),
        enableFiltering: true,
        enableCaseInsensitiveFiltering: true,
        maxHeight: 400
      }).multiselect();

      // TODO : it doesn't seems it's used in the system anymore
      // $('#edit_product_submit_btn').click( function() {
      //
      //       $('input.dynamical-required').each(
      //         function () {
      //           if ( $(this).val().length == 0 ) {
      //             console.log('yes');
      //             $(this).addClass('invalidBorderClass');
      //           } else {
      //             $(this).removeClass('invalidBorderClass');
      //           }
      //         }
      //       );
      //
      //       if ( $('.invalidBorderClass').length > 0 ) {
      //         return false;
      //       }
      //
      //     });
      //
      //     $('a[rel=popover]').popover();
      //
      //     var panel_cnt = $("#variants_panel_"+productId).children('.panel-body').find('.panel').length
      //     if (panel_cnt == 0) $("#a_add_variant_"+productId).click();
    }
  }

};

module.exports = ProductForm;
});

require.register("javascripts/starters/products_list.js", function(exports, require, module) {
"use strict";

/**
 * ProductsList Class
 */
var ProductsList = { // CURRENTLY NOT IN USED IN THE SYSTEM

  /**
   * Initializer
   */
  init: function init() {

    this.manageProductsWall();
  },

  manageProductsWall: function manageProductsWall() {}

};

module.exports = ProductsList;
});

require.register("javascripts/starters/qrcode.js", function(exports, require, module) {
'use strict';

/**
 * QrCode Class
 */
var QrCode = {

  initialized: false,

  /**
   * Initializer
   */
  init: function init() {

    $(window).on('resize', _.debounce($.proxy(this.onResize, this), 300)).trigger('resize');
  },

  onResize: function onResize(e) {

    if (this.isMobile() && this.initialized) {
      this.destroy();
      return;
    }

    if (this.isMobile()) {
      return;
    }

    if (!this.initialized) {
      this.setupWechat();
      this.setupWeibo();
      this.initialized = true;
      return;
    }
  },

  isMobile: function isMobile() {
    /**
     * NOTE : this 994 matches with the breakpoint of `=breakpoint` in SASS
     * Please be careful and change the one in the SASS as well
     */
    return $(window).width() <= 994;
  },

  destroy: function destroy() {
    $('#weibo-qr-code-trigger').off('mouseover').off('mouseout');
    $('#wechat-qr-code-trigger').off('mouseover').off('mouseout');
    $('#wechat-qr-code').addClass('hidden');
    $('#weibo-qr-code').addClass('hidden');
    QrCode.initialized = false;
  },

  setupWechat: function setupWechat() {

    $('#wechat-qr-code-trigger').on('mouseover', function (e) {
      $('#wechat-qr-code').removeClass('hidden');
    });

    $('#wechat-qr-code-trigger').on('mouseout', function (e) {
      $('#wechat-qr-code').addClass('hidden');
    });
  },

  setupWeibo: function setupWeibo() {

    $('#weibo-qr-code-trigger').on('mouseover', function (e) {
      $('#weibo-qr-code').removeClass('hidden');
    });

    $('#weibo-qr-code-trigger').on('mouseout', function (e) {
      $('#weibo-qr-code').addClass('hidden');
    });
  }

};

module.exports = QrCode;
});

require.register("javascripts/starters/refresh_time.js", function(exports, require, module) {
'use strict';

/**
 * RefreshTime Class
 */
var RefreshTime = {

  /**
   * Initializer
   */
  init: function init() {

    this.refreshTime('#utc-time', 'UTC');
    this.refreshTime('#china-time', 'Asia/Shanghai');
    this.refreshTime('#germany-time', 'Europe/Berlin');
  },

  /**
   * Change the current time html
   * @param  {#} selector
   * @return void
   */
  displayTime: function displayTime(selector, time_zone) {
    var time = moment().tz(time_zone).format('HH:mm:ss');
    $(selector).html(time);
  },

  /**
   * Activate the time refresh for specific selector
   * @param  {#} selector
   * @return void
   */
  refreshTime: function refreshTime(selector, time_zone) {
    var remote_time = $(selector).html();
    if (typeof remote_time != "undefined") {
      setInterval(function () {
        RefreshTime.displayTime(selector, time_zone);
      }, 1000);
    }
  }

};

module.exports = RefreshTime;
});

require.register("javascripts/starters/responsive.js", function(exports, require, module) {
'use strict';

/**
 * Responsive Class
 */
var Responsive = {

  /**
   * Initializer
   */
  init: function init() {

    this.manageCategoriesMenu();
  },

  manageCategoriesMenu: function manageCategoriesMenu() {

    if ($('.mobile-category-menu').length > 0) {

      var Translation = require('javascripts/lib/translation');

      $('#categories-menu').slicknav({

        "prependTo": ".mobile-category-menu", //".container-fluid"
        "label": Translation.find('menu', 'button'),
        "closeOnClick": true

      });

      // We hook the slicknav menu with some HTML content
      // It will occur after the menu is ready.
      // To stay clean it takes an invisible element within the HTML
      var left_side_content = $('#categories-menu-left-side').html();
      $('.slicknav_menu').prepend(left_side_content);
    }
  }

};

module.exports = Responsive;
});

require.register("javascripts/starters/search.js", function(exports, require, module) {
'use strict';

/**
 * Search Class
 */
var Search = {

  /**
   * Initializer
   */
  init: function init() {

    this.categoryFilter();
    this.searchInput();
  },

  /**
   * We make the search behavior
   */
  searchInput: function searchInput() {

    $('.js-search-button i').on('click', function (e) {
      e.preventDefault(); // prevent go back to the header
      Search.showSearchForm();
      $('.js-search-input').focus();
    });

    $('.js-search-input').on('focusout', function (e) {
      Search.hideSearchForm();
    });
  },

  showSearchForm: function showSearchForm() {
    $('.js-search-button').addClass('+hidden');
    $('.js-search-form').removeClass('+hidden');
  },

  hideSearchForm: function hideSearchForm() {
    $('.js-search-button').removeClass('+hidden');
    $('.js-search-form').addClass('+hidden');
  },

  /**
   * We make the category filter auto-trigger
   */
  categoryFilter: function categoryFilter() {

    $('.js-category-filter').on('change', function (e) {

      var category_id = $(this).val();

      var UrlProcess = require('javascripts/lib/url_process');
      UrlProcess.insertParam('category_id', category_id);
    });
  }

};

module.exports = Search;
});

require.register("javascripts/starters/sku_form.js", function(exports, require, module) {
'use strict';

/**
 * SkuForm Class
 * TODO : this classe should be moved over to the sku area only
 * it's not a starter or anything like that, spreading prop changes
 * on the global system is not safe.
 */
var SkuForm = {

  elements: {
    form: '#sku_form',
    checkbox: '#sku_unlimited',
    input: '#sku_quantity'
  },

  /**
   * Initializer
   */
  init: function init() {

    this.setupLimitSystem();
  },

  /**
   * If we are on the correct page containing `js-sku-form`
   * We setup the limit display and activate the checkbox click listener
   * @return {void}
   */
  setupLimitSystem: function setupLimitSystem() {

    if ($("#js-sku-form").length == 0) {
      return;
    }

    SkuForm.resetLimitDisplay();

    $(SkuForm.elements.checkbox).on('click', function () {
      SkuForm.resetLimitDisplay();
    });
  },

  /**
   * Reset the limit display
   * It will show or hide the input
   * @return {void}
   */
  resetLimitDisplay: function resetLimitDisplay() {
    if ($(SkuForm.elements.checkbox).is(":checked")) {
      SkuForm.switchOffLimit();
      return;
    }
    SkuForm.switchOnLimit();
  },

  /**
   * We disable the limit input and make it unlimited
   * @return {void}
   */
  switchOffLimit: function switchOffLimit() {
    $(SkuForm.elements.form).find(SkuForm.elements.input).val('0').prop('disabled', 'true').parent().hide();
  },

  /**
   * We activate the limit input and make it limited
   * @return {void}
   */
  switchOnLimit: function switchOnLimit() {
    $(SkuForm.elements.form).find(SkuForm.elements.input).removeAttr('disabled').parent().show();
  }

};

module.exports = SkuForm;
});

require.register("javascripts/starters/sweet_alert.js", function(exports, require, module) {
"use strict";

/**
 * SweetAlert Class
 */
var SweetAlert = {

  /**
   * Initializer
   */
  init: function init() {

    this.startAlert();
  },

  /**
   *
   */
  startAlert: function startAlert() {
    /*
          $.rails.allowAction = function(link){
      if (link.data("confirm") == undefined){
        console.log("fuck it");
        return true;
      }
      $.rails.showConfirmationDialog(link);
      return false;
    */
    //}

    /* NOT COMPATIBLE WITH RAILS SYSTEM ...
          $('.js-alert').click(function(e) {
    
            e.preventDefault();
            self = this;
    
            swal({
              title: $(self).data('title') || "Are you sure ?",
              text: $(self).data('text') || "This action cannot be undone.",
              type: "warning",
              showCancelButton: true,
              confirmButtonColor: "#DD6B55",
              confirmButtonText: "Yes, delete it!",
              closeOnConfirm: false
            }, function(){
              swal({
                title: "Processing!",
                text: "Your request is being processed ...",
                type: "success",
                showConfirmButton: false
              });
              window.location.href = $(self).attr('href');
            });
    
          })
    */
  }

};

module.exports = SweetAlert;
});

require.register("javascripts/starters/tooltipster.js", function(exports, require, module) {
'use strict';

/**
 * Tooltipster Class
 */
var Tooltipster = {

  /**
   * Initializer
   */
  init: function init() {

    this.activateTooltipster();
  },

  activateTooltipster: function activateTooltipster() {

    $('.tooltipster').tooltipster({
      'maxWidth': 350
    });
  }

};

module.exports = Tooltipster;
});

require.register("javascripts/starters/total_products.js", function(exports, require, module) {
'use strict';

/**
 * TotalProducts Class
 */
var TotalProducts = {

  /**
   * Initializer
   */
  init: function init() {

    this.refreshTotalProducts();
  },

  refreshTotalProducts: function refreshTotalProducts() {

    var refreshTotalProducts = require('../services/refresh_total_products');
    refreshTotalProducts.resolveHiding($('.js-total-products').html());
    //refreshTotalProducts.perform();
    // <-- NOTE : this will make a condition race
    // we found no solution but to just show manually and render from server side to avoid it.
  }
};

module.exports = TotalProducts;
});

require.register("___globals___", function(exports, require, module) {
  
});})();require('___globals___');


//# sourceMappingURL=app.js.map