class AttachmentUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage Rails.env.local? ? :file : :qiniu

  self.qiniu_can_overwrite = true

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def image?(new_file)
    self.file.content_type.include? 'image'
  end

  def not_image?(new_file)
    !self.file.content_type.include? 'image'
  end

  def extension_white_list
    %w(pdf)
  end
end