# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'germany_in_the_box'
set :repo_url, 'https://digpanda:achat2cool@bitbucket.org/digpanda/achat-backend-main.git'

set :passenger_environment_variables, { :path => '/usr/bin:$PATH' }
set :passenger_restart_command, '/usr/bin/passenger-config restart-app'

#set :linked_files, fetch(:linked_files, []).push('config/mongoid.yml', 'config/secrets.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do

      # brunch
      # execute "alias node=/home/ubuntu/.nvm/v5.0.0/bin/node | node -v" # we artifically set the node version
      execute "cd /var/www/germany_in_the_box/current/app_front && npm install && brunch build --production"
	   execute "chmod +x /var/www/germany_in_the_box/current/config/cron/dump_and_restore.sh"

      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
