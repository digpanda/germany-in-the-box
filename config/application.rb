require File.expand_path('../boot', __FILE__)

require 'rails'

require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'
require 'mobvious'
require 'http_accept_language'
require 'i18n/backend/fallbacks'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DigPanda
  class Application < Rails::Application
    # loading monkey patch modules
    require "#{config.root}/lib/core_extensions/numeric/currency_library"
    require "#{config.root}/lib/core_extensions/string/chinese_detection"
    Numeric.include CoreExtensions::Numeric::CurrencyLibrary # currency conversion
    String.include CoreExtensions::String::ChineseDetection # chinese? on strings

    config.debug_mode = false # homemade debug system will dispatch more information if `true`
    config.exceptions_app = self.routes # customized error handling
    config.autoload_paths += %W(#{config.root}/services #{config.root}/lib #{config.root}/app/decorators/concerns #{config.root}/app/uploaders/concerns)
    config.local = %W(locations)

    config.middleware.use Mongoid::QueryCache::Middleware
    config.middleware.use Mobvious::Manager
    config.middleware.use HttpAcceptLanguage::Middleware
    config.i18n.available_locales = %w(de zh-CN en)
    config.i18n.default_locale = :de
    #config.time_zone = 'Beijing'

    # Allow Anything on API gateways
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :put, :patch, :post, :options]
      end
    end

    # NOTE : A loop here will make everything heavier
    # and will force method definitions, better to keep it simple, sadly.
    config.gitb = YAML.load(ERB.new(File.read(Rails.root.join('config/germany_in_the_box.yml'))).result)[Rails.env].deep_symbolize_keys!
    config.qiniu = YAML.load(ERB.new(File.read(Rails.root.join('config/qiniu.yml'))).result)[Rails.env].deep_symbolize_keys!
    config.digpanda = YAML.load(ERB.new(File.read(Rails.root.join('config/digpanda.yml'))).result)[Rails.env].deep_symbolize_keys!
    config.wechat = YAML.load(ERB.new(File.read(Rails.root.join('config/wechat.yml'))).result)[Rails.env].deep_symbolize_keys!

    # No environment constraint
    config.errors = YAML.load(ERB.new(File.read(Rails.root.join('config/errors.yml'))).result).deep_symbolize_keys!

    # Delayed job
    config.active_job.queue_adapter = :delayed_job

    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    config.i18n.fallbacks = { 'de' => 'en', 'zh-CN' => 'en' }
    config.web_console.development_only = false if Rails.env.local?
  end
end
