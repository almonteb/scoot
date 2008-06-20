set :ssh_options, { :forward_agent => true }

set :repository, "."
set :scm, :git
set :deploy_via, :copy

# This shouldn't be here - why is it not picking up the local username automagically?
require 'etc'
set :runner, Etc.getlogin

role :app, "git.railscamp.net" #, "172.16.xxx.xxx"
role :db, "git.railscamp.net", :primary => true 

set :deploy_to, "/srv/rails/gitorious"

set :app_user, "git"

set :group, "appdeploy"

task :after_update_code, :roles => :app do
sudo <<-CMD
sh -c "chown -R #{app_user}:#{group} #{release_path} &&
chmod -R g+w #{release_path}"
CMD
end

namespace :deploy do
desc "Custom restart task for passenger"
task :restart, :roles => :app, :except => { :no_release => true } do
run "touch #{deploy_to}/current/tmp/restart.txt"
end

desc "Custom start task for passenger"
task :start, :roles => :app do
# Don't need to do anything, it's automatic
end

desc "Custom stop task for passenger"
task :stop, :roles => :app do
# currently no way I know of to 'stop' the app
end
end
