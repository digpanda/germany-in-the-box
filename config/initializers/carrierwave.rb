::CarrierWave.configure do |config|

  config.storage              = :qiniu
  config.qiniu_access_key     = 'sjmi6rq8r6Z7oO84m9WQ3grXZJNaDmBlHC5eDWsu'
  config.qiniu_secret_key     = 'Vp_6J0c4GZML4PESk5vMv6yVgTCYY7x4XtKt3JCj'
  config.qiniu_bucket         = Rails.env.production? ? 'carrierwave-laiyinn-prod' : 'carrierwave-laiyinn-staging'
  config.qiniu_bucket_domain  = Rails.env.production? ? 'o9fhtjfm2.qnssl.com' : 'o9fh2muer.qnssl.com'
  config.qiniu_bucket_private = true
  config.qiniu_block_size     = 4*1024*1024
  config.qiniu_protocol       = 'https'
  config.qiniu_up_host        = 'http://up.qiniug.com'

end
