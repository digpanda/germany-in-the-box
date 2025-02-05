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
  init: function() {

    this.validateImageFile();
    this.imageLiveRefresh();

  },

  /**
  * Validate the image itself when it's changed
  * @return {void}
  */
  validateImageFile: function() {

    $(ImagesHandler.elements.image).on('change', function() {

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

      $.each(inputFile.files, function() {
        if (this.size && maxFileSize && this.size > maxFileSize) {sizeExceeded=true;};
        extName = this.name.split('.').pop();
        if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
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
  imageLiveRefresh: function() {

    if ($(ImagesHandler.elements.image).length > 0) {

      $(ImagesHandler.elements.image).each(function() {

        var fileElement = $(this)

        $(this).change(function(event){
          var input = $(event.currentTarget);
          var file = input[0].files[0];
          var reader = new FileReader();
          reader.onload = function(e){
            var image_base64 = e.target.result;

            let image_div = fileElement.attr('image_selector');
            $(image_div).attr("src", image_base64);

            // we show the update
            let add_link = fileElement.attr('image_selector')+'_add';
            $(add_link).removeClass('hidden');

          };
          reader.readAsDataURL(file);
        });

      });

    }

  },

}

module.exports = ImagesHandler;
