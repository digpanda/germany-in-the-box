/**
 * ManageCart class
 */
var ManageCart = {

  /**
   * Initializer
   */
   init: function() {

    this.onSetAddress();
    this.multiSelectSystem();

  },

  multiSelectSystem: function() {

    $('select.sku-variants-options').multiselect({
      enableCaseInsensitiveFiltering: true,
      maxHeight: 400,
    }).multiselect('disable');

  },

  onSetAddress: function() {

/*
    $(".js-set-address-link").click(function(e) {

      e.preventDefault();
      ManageCart.forceLogin(this);

    });
*/
  },

  /**
   * Send next destination and trigger log-in if not logged-in already
   */
   forceLogin: function(el) {

/* WE DEPRECATED WITH THE NEW LOGIN SYSTEM
    var location = $(el).attr("href");
    var self = this;

    var User = require("javascripts/models/user");

    User.isAuth(function(res) {

      // If the user isn't auth
      // We force the trigger and
      // Set the new location programmatically
      if (res === false) {

        self.setRedirectLocation(location);
        $("#sign_in_link").click();

      } else {

        // Else we just continue to do what we were doing
        window.location.href = location;
        
      }

    });
*/
  },

/* SAME HERE
  // Should be in a lib
  setRedirectLocation: function(location) {

    $.ajax({
      method: "PATCH",
      url: "api/set_redirect_location",
      data: {"location": location}


    }).done(function(res) {

      // callback {"status": "ok"}

    });

  },
*/

}

module.exports = ManageCart;