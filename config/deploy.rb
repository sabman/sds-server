#
# READ doc/readme_install.md for documentation
#
require "bundler/capistrano"
set :bundle_flags, "--deployment --quiet --binstubs"

load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/postgresql"
load "config/recipes/nodejs"
load "config/recipes/rbenv"
load "config/recipes/check"


server "192.168.15.139", :web, :app, :db, :primary => true
set :user, "tim"
set :application, "sds-server"


set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :default_environment, {
  'PATH' => "/home/#{user}/.rbenv/shims:/home/#{user}/.rbenv/bin:$PATH"
}

set :scm, "git"
set :repository, "git@github.com:hotosm/#{application}.git"
set :branch, "develop"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases

before "deploy", "deploy:create_release_dir"
namespace :deploy do
  task :create_release_dir, :except => {:no_release => true} do
    run "mkdir -p #{fetch :releases_path}"
  end
end

namespace :bundler do
  task :create_symlink, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(release_path, '.bundle')
    run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
  end

  task :install, :roles => :app do
    run "cd #{release_path} && bundle install"

    on_rollback do
      if previous_release
        run "cd #{previous_release} && bundle install"
      else
        logger.important "no previous release to rollback to, rollback of bundler:install skipped"
      end
    end
  end

  task :bundle_new_release, :roles => :db do
    bundler.create_symlink
    bundler.install
  end
end
before "deploy:assets:precompile", "bundler:bundle_new_release"

namespace :deploy do
  desc "Run the remote create_admin rake task"
  task :create_admin do
    rake = fetch(:rake, 'rake')
    rails_env = fetch(:rails_env, 'production')

    run "cd '#{current_path}' && #{rake} db:create_admin[Admin,Adminson,admin@example.com,changemeplease] RAILS_ENV=#{rails_env}"
  end
end

after "deploy:create_symlink","uploads:create_symlink"

namespace :uploads do
  desc "creates a symlink between the public uploads directory and shared so that the uploads will persist between deployments"
  task :create_symlink do
    run "mkdir -p #{shared_path}/presets"
    run "rm -rf #{release_path}/pubic/presets"
    run "ln -nfs #{shared_path}/presets #{release_path}/public/presets"
  end
end

after "deploy:create_symlink", "deploy:symlink_app_config"
namespace :deploy do
  task :symlink_app_config do
    run "cp -n  #{release_path}/config/app_config.yml.example  #{shared_path}/config/app_config.yml"  #copy the example file unless already exists
    run "ln -s #{shared_path}/config/app_config.yml #{release_path}/config/" #link the example file to shared
  end
end
