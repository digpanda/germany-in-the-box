source "https://rubygems.org"

# Loschcode gems
# for casual installation, just use the version (e.g. "0.1.1")
# the git repo is locally override, i need to detail the remote repo for it to work
# for direct local change without repo, use :path => "../../wirecard-elastic"
gem "wirecard-elastic", git: "https://github.com/Loschcode/wirecard-elastic.git", branch: "master", tag: "v0.2.2"

gem "alipay", "~> 0.14.0"
gem "wx_pay"
gem "rqrcode"

gem "geocoder"
gem "api_cache"
gem "thin"
gem "rails", "4.2.1"
gem "mongoid", "~> 5.0.0"
gem "mongoid_includes"
gem "mongoid_rails_migrations"
gem "mongoid_search", github: "Loschcode/mongoid_search", branch: "master"

gem "country_select"
gem "slack-notifier"
gem "delayed_job_mongoid"
gem "daemons"
gem "figaro"
gem "turnout"
gem "business_time"
gem "mailgun_rails"
gem "whenever", :require => false # cron job handling
gem "wkhtmltopdf-binary" # pdf generation (we need it coupled with wicked_pdf)
gem "wicked_pdf" # pdf generation
gem "breadcrumbs_on_rails"
gem "sass-rails", "~> 5.0.3"
gem "uglifier", ">= 1.3.0" # Use Uglifier as compressor for JavaScript assets
gem "turbolinks" # Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem "jbuilder", "~> 2.0" # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "sdoc", "~> 0.4.0", group: :doc # bundle exec rake doc:rails generates the API under doc/api.
gem "devise", "3.5.3"
#gem "omniauth-facebook"
gem "draper", "~> 1.3" # decorators
gem "draper-cancancan"
gem "carrierwave-mongoid", :require => "carrierwave/mongoid"

gem "mini_magick"
gem "haml-rails"
gem "easy_captcha"
gem "rmagick"
gem "diff-lcs", "1.2.5"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "china_city"
gem "mobvious-rails"
gem "simple_token_authentication"
gem "genderize"
gem "strip_attributes"
gem "will_paginate"
gem "will_paginate-bootstrap"
gem "bootstrap-multiselect-rails"
gem "cancancan", "1.13.1"
gem "http_accept_language"
gem "jquery-fileupload-rails"
gem "copy_carrierwave_file"
gem "delocalize"
gem "carrierwave-qiniu"
gem "countries"
gem "oauth"
gem "magnific-popup-rails"
gem "font-awesome-rails"
gem "twitter-bootstrap-rails"
gem "bootstrap-datepicker-rails"
gem "bootstrap-validator-rails"
gem "abstract_method"
gem "mongoid_magic_counter_cache"
gem "carrierwave-ftp", :require => "carrierwave/storage/ftp" # FTP only
gem "sidekiq"
gem "redis-rails"

gem "omniauth"
gem "omniauth-wechat-oauth2", git: "https://github.com/yangsr/omniauth-wechat-oauth2.git"

gem "exception_notification"
#gem "omniauth-open_wechat"
#gem "newrelic_rpm"
#gem "newrelic_moped"

group :development do
  gem "capistrano"
  gem "capistrano-bundler"
  gem "capistrano-passenger", ">= 0.1.1"
  gem "capistrano-rails"
  gem "capistrano-rvm"
  gem "capistrano-nvm"
  gem "capistrano-linked-files"
  gem "capistrano-secrets-yml", "~> 1.0.0"
  gem "capistrano-sidekiq"

  # debug / metrics
  gem "flay"
  gem "flog"
  gem "rubocop", require: false

end

group :development, :test do
  gem "vcr"
  gem "webmock" # http service loader
end

group :development, :test, :staging, :local do
  gem "factory_girl_rails"
  gem "rspec-rails", "~> 3.0"
  gem "capybara"
  gem "poltergeist", "1.15.0"
  gem "selenium-webdriver"
  gem "chromedriver-helper"
  #gem "mongoid-rspec", "3.0.0"
  #gem "cucumber-rails", :require => false
  gem "database_cleaner"
  gem "pry-rails"
end

group :development, :local do
  gem "spring" # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "better_errors"
  gem "minitest", "5.8.3"
  gem "faker"

end
