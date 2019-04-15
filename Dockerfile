FROM ruby:2.5.0-alpine as build-stage
RUN apk add --update build-base py-pygments
ADD . /app
WORKDIR /app
RUN bundle install
RUN bundle exec jekyll build

FROM infoslack/caddy
COPY --from=build-stage /app/_site /blog
