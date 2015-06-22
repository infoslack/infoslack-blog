require "mina/bundler"
require "mina/git"

set :domain, "infoslack.com"
set :user, "deploy"
set :deploy_to, "/var/www/infoslack"
set :repository, "https://github.com/infoslack/infoslack-jekyll.git"
set :branch, "master"
set :shared_paths, ["_site/metasploit", "_site/docker", "_site/inscricao.html", "_site/workshops", "_site/ansible"]

task :setup => :environment do
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/_site/inscricao.html"]
end

task :deploy => :environment do
  deploy do
    invoke :"git:clone"
    invoke :"bundle:install"
    queue "bundle exec jekyll build --lsi"
    invoke :"deploy:link_shared_paths"
  end
end
