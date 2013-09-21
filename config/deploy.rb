set :application, "infoslack.com"

set :keep_releases, 3
set :repository, "./_deploy"
set :scm, :none

set :use_sudo, false
set :user, "deploy"
set :port, 22

set :deploy_to, "/var/www/infoslack"
set :deploy_via, :copy
set :copy_strategy, :export

role :app, application
role :web, application

after "deploy", "deploy:cleanup"

namespace :deploy do
  [:start, :stop, :restart, :finalize_update].each do |t|
    desc "#{t} task is a no-op with jekyll"
    task t, :roles => :app do ; end
  end
end
