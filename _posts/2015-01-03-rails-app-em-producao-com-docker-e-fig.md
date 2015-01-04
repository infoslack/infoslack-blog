---
layout: post
title: "Rails em produção com Docker e Fig"
description: "Deploy de app Rails em produção utilizando Docker e Fig"
category: devops
keywords: linux, deploy, devops, lxc, docker, container, ruby, rails, fig
---

Já mostrei em outros posts as facilidades do Docker e como é rápido por
uma app web com banco de dados em funcionamento. Hoje apresento o [Fig](http://www.fig.sh/)
que veio para simplificar todo o processo de criação de containers Docker,
usaremos ambos para por uma app Rails em produção.

### Introdução

As [boas práticas de Dockerising](https://docs.docker.com/articles/dockerfile_best-practices/) dizem que você deve ter apenas 1 serviço
em execução por container criado, no exemplo temos 3 serviços:

- PostgreSQL
- App Rails
- Nginx

No projeto Rails temos 2 novos arquivos o `fig.yml` e um `Dockerfile`,
não foi necessário controlar o Dockerfile de imagens do PostgreSQL ou do
Nginx, no próprio Fig é possível especificar o nome da imagem que será
usada na criação de cada container e ele entende que caso a imagem não
exista no host ele deve fazer um pull do [Docker Hub](https://registry.hub.docker.com/).

### O Dockerfile

O Dockerfile utilizado no projeto é super simples e contém apenas uma
chamada para o nome de uma imagem personalizada:

{% highlight bash %}
$ cat Dockerfile
FROM infoslack/rails:onbuild
{% endhighlight %}

A imagem `infoslack/rails:onbuild` em sua receita faz uso de instruções
`ONBUILD` onde é possível adiar a execução de algumas tarefas:

{% highlight bash %}
FROM infoslack/docker-ruby

MAINTAINER Daniel Romero <infoslack@gmail.com>

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ONBUILD COPY Gemfile /usr/src/app/
ONBUILD COPY Gemfile.lock /usr/src/app/
ONBUILD RUN bundle install

ONBUILD COPY . /usr/src/app

RUN apt-get update \
		&& apt-get install -y nodejs --no-install-recommends \
		&& rm -rf /var/lib/apt/lists/*

RUN apt-get update \
		&& apt-get install -y \
		mysql-client \
		postgresql-client \
		sqlite3 \
		--no-install-recommends \
		&& rm -rf /var/lib/apt/lists/*

EXPOSE 3000
CMD ["rails", "server"]
{% endhighlight %}

Basicamente a receita herda de outra imagem que já possui a instalação
do Ruby e prepara o ambiente para executar a aplicação Rails, apenas 
quando a imagem referente ao projeto for criada as tasks onbuild serão
disparadas. 

O bom desta abordagem é que sempre que a imagem do projeto sofrer 
alterações a tarefa do `bundle install` será verificada no cache do 
Docker, ou seja se o seu `Gemfile.lock` não sofreu alterações a execução 
do bundle é ignorada.

### Fig

Para configurar o Fig no projeto só precisamos de um arquivo `fig.yml`,
nele teremos algo assim:

{% highlight bash %}
$ cat fig.yml
db:
	image: postgres:9.3
	volumes:
		- ~/.docker-volumes/blog/db/:/var/lib/postgresql/data/
	expose:
		- 5432

app:
	build: .
	command: bundle exec puma -p 9001 -e production
	environment:
		- RAILS_ENV=production
	volumes:
		- .:/usr/src/app
	expose:
		- 9001
	links:
		- db

web:
	image: infoslack/nginx-puma
	volumes_from:
		- app
	ports:
		- 80:80
	links:
		- app
{% endhighlight %}

No Fig separamos cada serviço que será executado e de quais imagens eles
devem ser criados, no exemplo o `db` está usando a [imagem oficial](https://registry.hub.docker.com/_/postgres/) do
Postgres.

Em `app` não declaramos a imagem pois queremos que ela seja criada partindo
do Dockerfile existente no projeto, em vez disso usamos a opção `build`,
em seguida temos o `command` onde disparamos o puma na porta 9001.

É possível manter diferentes environments no fig, no nosso exemplo estou
setando apenas o de `production`. Na última opção temos o `links` onde
informo o nome do serviço que o container de `app` terá relacionamento.
Este relacionamento permite utilizarmos o nome do serviço em vez do número
ip em algumas configurações, como por exemplo o `database.yml`:

{% highlight bash %}
$ cat config/database.yml
production:
	adapter: postgresql
	enconding: unicode
	pool: 5
	username: postgres
	password:
	database: app_rails_demo
	host: db
{% endhighlight %}

O mesmo vale para o serviço `web` onde o container para o Nginx será 
criado, nas configurações do nginx basta informar o nome do serviço em
vez do ip do container da aplicação rails:

{% highlight bash %}
...
upstream rails {
	server app:9001 fail_timeout=0;
}
...
{% endhighlight %}

### Inicializando a aplicação

Para a primeira inicialização da app podemos carregar o serviço de `db`
sozinho em background e em seguida rodar o `rake db:setup`:

{% highlight bash %}
$ fig up -d db
Creating blog_db_1...
$ fig run --rm app rake db:setup
app_rails_prod already exists
-- enable_extension("plpgsql")
-> 0.0247s
-- create_table("comments", {:force=>:cascade})
-> 0.0423s
...
-- initialize_schema_migrations_table()
-> 0.0053s
Removing blog_app_run_1...
{% endhighlight %}

Na segunda tarefa utilizei a opção `run` do fig para criar um container
intermediário apenas para executar o `rake db:setup` e depois ele foi
destruído.

Agora posso inicializar a aplicação com o comando `fig up`:

{% highlight bash %}
$ fig up
Recreating blog_db_1...
Creating blog_app_1...
Creating blog_web_1...
Attaching to blog_db_1, blog_app_1, blog_web_1
app_1 | Puma starting in single mode...
app_1 | * Version 2.10.2 (ruby 2.2.0-p0), codename: Robots on Comets
app_1 | * Min threads: 0, max threads: 16
app_1 | * Environment: production
app_1 | * Listening on tcp://0.0.0.0:9001
app_1 | Use Ctrl-C to stop
{% endhighlight %}

Os containers serão criados e linkados e os serviços inicializados, mas
claro que em produção a execução do fig será em background: `fig up -d`,
utilizando a opção `ps` podemos ver os 3 containers criados:

{% highlight bash %}
$ fig ps

Name		Command					State	Ports
------------------------------------------------------
r_app_1		bundle exec puma ...	Up		3000/tcp
r_dba_1		docker-entrypoint...	Up		5432/tcp                              
r_web_1		nginx -g daemon  ...	Up		80/tcp
{% endhighlight %}

Algumas tarefas não foram automatizadas como por exemplo o 
`rake assets:precompile` essa tarefa poderia ser executada por um 
container intermediário:

{% highlight bash %}
$ fig run --rm app rake assets:precompile
{% endhighlight %}

Ou poderiamos criar uma regra de `ONBUILD` no Dockerfile. Sempre que um
deploy for feito com alterações no projeto, o fig pode executar a tarefa
`build` para aplicar as mudanças na imagem da aplicação:

{% highlight bash %}
$ fig build app
{% endhighlight %}

Podemos conferir a aplicação funcionando normalmente aqui: [http://54.172.19.70](http://54.172.19.70)

### Finalizando

Abordarei sobre formas de deploy contínuo em outros posts, mas por 
enquanto você poderia usar a sua ferramenta de deploy favorita sem 
maiores problemas, ela apenas enviaria a aplicação para o host e a
execução do fig poderia ser automatizada com monit por exemplo.

Não deixe de conferir os links com os códigos dos exemplos e se você
ficou interessado na combinação Docker + Fig vai rolar um workshop de
**05/01/15 a 09/01/15**, mais detalhes em: [http://infoslack.com/workshops/docker/](http://infoslack.com/workshops/docker/)

Happy Hacking ;)

### Referências

- [https://github.com/infoslack/rails_docker_demo](https://github.com/infoslack/rails_docker_demo)
- [http://www.fig.sh/yml.html](http://www.fig.sh/yml.html)
- [https://github.com/infoslack/docker-nginx](https://github.com/infoslack/docker-nginx)
- [https://github.com/infoslack/docker-rails](https://github.com/infoslack/docker-rails)
- [https://github.com/infoslack/docker-ruby](https://github.com/infoslack/docker-ruby)
- [https://docs.docker.com/userguide/dockerlinks/](https://docs.docker.com/userguide/dockerlinks/)
- [https://docs.docker.com/reference/builder/#onbuild](https://docs.docker.com/reference/builder/#onbuild)
- [https://hub.docker.com/u/infoslack/](https://hub.docker.com/u/infoslack/)
- [https://registry.hub.docker.com/_/postgres/](https://registry.hub.docker.com/_/postgres/)
- [https://docs.docker.com/articles/dockerfile_best-practices/](https://docs.docker.com/articles/dockerfile_best-practices/)
