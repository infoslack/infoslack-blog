set :stage, :production

role :app, %w{deploy@infoslack.com}
role :web, %w{deploy@infoslack.com}
role :db,  %w{deploy@infoslack.com}
