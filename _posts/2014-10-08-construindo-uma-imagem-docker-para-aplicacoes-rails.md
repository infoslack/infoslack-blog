---
layout: post
title: "Construindo uma imagem Docker para aplicações Rails"
category: linux
keywords: linux, deploy, virtualização, lxc, docker, container, ruby, rails
---

Continuando a série sobre Docker, hoje veremos como construir uma imagem Docker
preparada para executar aplicações Rails. Se você ainda não viu o post anterior sobre os
primeiros passos com Docker, acesse e veja:[http://infoslack.com/linux/docker-primeiros-passos/](http://infoslack.com/linux/docker-primeiros-passos/).

Bem antes de continuar, tenha em mente que o Dockerfile que será criado, vai
gerar a imagem base para a construção de containers direto no servidor a aplicação Rails
poderá ser hospedada, pois quero que minha imagem e as informações de configuração relacionadas
a app sejam privadas, apesar de podermos criar um registro privado no [https://registry.hub.docker.com/](https://registry.hub.docker.com/),
farei da maneira mais simples neste post ;)

### Dockerfile

Para começar, no host teremos um diretório com o Dockerfile e alguns arquivos de configuração
do Nginx que serão utilizados na construção da imagem. No arquivo Dockerfile teremos as
instruções base para instalar o Nginx e o Ruby:

{% highlight bash %}
FROM ubuntu:trusty

# Update the repository
RUN apt-get update

# Install necessary tools
RUN apt-get install -y wget net-tools build-essential git

# Setup Install Nginx
RUN wget -q -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN echo 'deb http://nginx.org/packages/ubuntu/ trusty nginx' | tee /etc/apt/sources.list.d/nginx.list

# Setup Install Ruby
RUN wget -q -O - http://apt.hellobits.com/hellobits.key | apt-key add -
RUN echo 'deb [arch=amd64] http://apt.hellobits.com/ trusty main' | tee /etc/apt/sources.list.d/hellobits.list

# Install Nginx and Ruby
RUN apt-get update
RUN apt-get install -y nginx ruby-2.1

# Install Bundler
RUN gem install bundler

# Copy Nginx files
ADD nginx.conf /etc/nginx/nginx.conf
ADD myapp.conf /etc/nginx/sites/myapp.conf
{% endhighlight %}

A novidade no Dockerfile é o `ADD` que copia arquivos locais no host para
o PATH na imagem que será preparada. Com esse modelo já podemos criar nossa
imagem e testar:

{% highlight bash %}
$ docker build -t docker_on_rails .
{% endhighlight %}

O nome dado a imagem foi `docker_on_rails`, se verificarmos as imagens disponíveis
veremos a base que é o Ubuntu 14.04 (trusty) e a nossa imagem:

{% highlight bash %}
$ docker images

REPOSITORY        TAG      IMAGE ID       CREATED        VIRTUAL SIZE
docker_on_rails   latest   7f947af605e8   3 minutes ago  385.1 MB
ubuntu            trusty   6b4e8a7373fe   6 days ago     194.8 MB
{% endhighlight %}

Podemos conferir nossa instalação criando um container apartir da nossa imagem,
para isso:

{% highlight bash %}
$ docker run --rm -i -t docker_on_rails /bin/bash
root@3cefe7708ace:/# ruby -v
ruby 2.1.3p242 (2014-09-19 revision 47630) [x86_64-linux]
root@3cefe7708ace:/# nginx -v
nginx version: nginx/1.6.2
root@3cefe7708ace:/#
{% endhighlight %}

Tudo foi instalado corretamente.

### Executando o container

Com base na imagem criada, poderiamos inicializar um container em background:

{% highlight bash %}
$ docker run -d -p 80:80 docker_on_rails
{% endhighlight %}

Porém teriamos que passar instruções ainda para inicializar o nginx, em vez disso
vamos melhorar o Dockerfile para que ele faça o mapeamento da porta 80 e possa
inicializar o Nginx sempre que um container for criado:

{% highlight bash %}
...
# Ports
EXPOSE 80

# Start nginx
CMD ["/usr/sbin/nginx","-c","/etc/nginx/nginx.conf","-g","daemon off;"]
{% endhighlight %}

Para que essa alteração possa valer, precisamos atualizar nossa imagem:

{% highlight bash %}
$ docker build -t docker_on_rails .
{% endhighlight %}

E para o container conseguir ler os arquivos da aplicação rails que vai
ficar sempre disponível no host, podemos utilizar a diretiva `WORKDIR` no
Dockerfile:

{% highlight bash %}
...
# set workdir
WORKDIR /home/ubuntu/my_app

# Ports
EXPOSE 80
...
{% endhighlight %}

Podemos aproveitar e informar no Dockerfile onde ele deverá replicar os arquivos
lidos em `WORKDIR`, como as regras do Nginx estão apontando para `/var/www`, a
configuração poderia ser assim:

{% highlight bash %}
...
# set workdir
WORKDIR /home/ubuntu/my_app
ADD . /var/www/my_app/
...
{% endhighlight %}

Depois de gerar a imagem novamente e acessar o container é possível verificar
que os arquivos relacionados a aplicação rails estão sendo exibidos em
`/var/www/my_app`:

{% highlight bash %}
$ docker build -t docker_on_rails .
$ docker run --rm -i -t docker_on_rails /bin/bash
$ ll /var/www/my_app/
total 84
drwxr-xr-x 12 root     root     4096 Oct  8 04:45 ./
drwxrwxr-x  3 www-data www-data 4096 Oct  8 04:45 ../
-rw-r--r--  1 root     root      466 Oct  8 04:22 .gitignore
-rw-r--r--  1 root     root      951 Oct  8 04:45 Dockerfile
-rw-r--r--  1 root     root     1339 Oct  8 04:22 Gemfile
-rw-r--r--  1 root     root     2871 Oct  8 04:22 Gemfile.lock
-rw-r--r--  1 root     root      478 Oct  8 04:22 README.rdoc
-rw-r--r--  1 root     root      249 Oct  8 04:22 Rakefile
drwxr-xr-x  8 root     root     4096 Oct  8 04:22 app/
drwxr-xr-x  2 root     root     4096 Oct  8 04:22 bin/
drwxr-xr-x  5 root     root     4096 Oct  8 04:22 config/
-rw-r--r--  1 root     root      154 Oct  8 04:22 config.ru
drwxr-xr-x  2 root     root     4096 Oct  8 04:22 db/
drwxr-xr-x  4 root     root     4096 Oct  8 04:22 lib/
drwxr-xr-x  2 root     root     4096 Oct  8 04:22 log/
-rw-r--r--  1 root     root     1006 Oct  8 04:29 myapp.conf
-rw-r--r--  1 root     root     1331 Oct  8 04:29 nginx.conf
drwxr-xr-x  2 root     root     4096 Oct  8 04:22 public/
drwxr-xr-x  8 root     root     4096 Oct  8 04:22 test/
drwxr-xr-x  6 root     root     4096 Oct  8 04:22 tmp/
drwxr-xr-x  3 root     root     4096 Oct  8 04:22 vendor/
{% endhighlight %}

Para testar a nova imagem e a aplicação funcionando, basta criar um novo container:

{% highlight bash %}
$ docker run -p 80:80 -i -t docker_on_rails /bin/bash
$ cd /var/www/my_app/
$ bundle install
$ bundle exec unicorn -c config/unicorn.rb
{% endhighlight %}

![Rails app run Docker](/images/rails-app-ok.png)

### Conclusão

Todo o comportamento dos containers pode ser preestabelecido na imagem que
será utilizada, ou seja, tarefas como `bundle install`, scripts de upstart
para o Unicorn ou para a própria aplicação podem ser adicionados ao Dockerfile.

Nos próximos posts sobre Docker tentarei abordar o uso da diretiva `VOLUME`,
a instalação de um banco de dados e uma demonstração real de deploy.

Os arquivos utilizados neste post estão aqui: [https://gist.github.com/infoslack/93b9e89ac97c9775880f](https://gist.github.com/infoslack/93b9e89ac97c9775880f)

Happy Hacking ;)

### Referências

- [https://docs.docker.com/userguide/dockerizing/](https://docs.docker.com/userguide/dockerizing/)
- [https://docs.docker.com/userguide/dockerimages/](https://docs.docker.com/userguide/dockerimages/)
- [https://docs.docker.com/userguide/dockerlinks/](https://docs.docker.com/userguide/dockerlinks/)
