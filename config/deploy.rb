require "mina/git"

set :domain, "infoslack.com"
set :user, "deploy"
set :deploy_to, "/var/www/infoslack"
set :repository, "https://github.com/infoslack/infoslack-jekyll.git"
set :branch, "deploy"

task :deploy do
  deploy do
    invoke :"git:clone"
  end
end
