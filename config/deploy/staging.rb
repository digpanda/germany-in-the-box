role :app, %w{ubuntu@germanyintheboxdev.com}
role :web, %w{ubuntu@germanyintheboxdev.com}
role :db,  %w{ubuntu@germanyintheboxdev.com}

set :rvm_ruby_version, '2.3.0'
set :rvm_type, :user
set :rvm_custom_path, '/usr/share/rvm'

set :nvm_node, 'v5.0.0'
set :nvm_type, :user
set :nvm_map_bins, %w{node npm}
#set :nvm_custom_path, '/home/ubuntu/.nvm/bin'

set :ssh_options, {
  keys: %w(/Users/haojiang/Downloads/keys/digpanda.pem),
  forward_agent: true,
  auth_methods: %w(publickey, password)
}

set :branch, ENV['BRANCH'] || :staging
