FROM ruby:3.0.2 as build-stage
ADD . /app
WORKDIR /app
RUN gem install bundler && bundle install
RUN bundle exec jekyll build

FROM infoslack/caddy
COPY --from=build-stage /app/_site /blog
