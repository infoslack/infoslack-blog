require "mina/bundler"
require "mina/git"

set :domain, "infoslack.com"
set :user, "deploy"
set :deploy_to, "/var/www/infoslack"
set :repository, "https://github.com/infoslack/infoslack-jekyll.git"
set :branch, "master"

task :deploy do
  deploy do
    invoke :"git:clone"
    invoke :"bundle:install"
    queue "#{bundle_prefix} jekyll --lsi build"
  end
end
