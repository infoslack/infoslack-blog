---
layout: post
title: "Conteinerização de PostgreSQL com Docker"
description: "Criando um container Docker para postgresql e integrando a uma aplicação rails"
category: linux
keywords: linux, deploy, virtualização, lxc, docker, container, ruby, rails, postgresql
---

Este post é uma continuação da saga sobre Docker ;)
Se você ainda não leu os posts anteriores:
- [Primeiros passos com Docker](http://infoslack.com/linux/docker-primeiros-passos/)
- [Construindo uma imagem Docker para aplicações Rails](http://infoslack.com/linux/construindo-uma-imagem-docker-para-aplicacoes-rails/)

### Gerando a imagem

Assumindo que você já deu uma olhada nos outros posts e entende o básico
sobre como trabalhar com o Docker vamos ao que interessa, o primeiro passo
aqui será construir nossa imagem Docker para trabalhar com o PostgreSQL,
vamos analisar o Dockerfile:

{% highlight bash %}
FROM ubuntu:trusty

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

RUN apt-key adv --keyserver keyserver.ubuntu.com \
  --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive \
  apt-get install -y -q postgresql-9.3 postgresql-contrib-9.3 \
  libpq-dev python-software-properties software-properties-common \
  postgresql-client-9.3

ADD postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
ADD pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf

RUN chown -R postgres:postgres /etc/postgresql/9.3/main/

ADD run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

VOLUME ["/var/lib/postgresql"]

EXPOSE 5432

CMD ["/usr/local/bin/run"]
{% endhighlight %}

A novidade aqui é o `VOLUME` que é um recurso do Docker para especificar
um diretório que pode ser persistido ou compartilhado dentro do **container**.
As alterações em um volume não serão persistidas quando você fizer atualizações
em uma imagem, veremos mais adiante detalhes de como trabalhar com volumes.

Para gerar a imagem estou informando no Dockerfile que ele deve copiar
alguns arquivos de configuração do Postgresql durante a instalação. Vamos
conferir o script de inicialização do postgres:

{% highlight bash %}
#!/bin/bash
set -e

POSTGRESQL_USER=${POSTGRESQL_USER:-"docker"}
POSTGRESQL_PASS=${POSTGRESQL_PASS:-"docker"}
POSTGRESQL_DB=${POSTGRESQL_DB:-"docker"}
POSTGRESQL_TEMPLATE=${POSTGRESQL_TEMPLATE:-"DEFAULT"}

POSTGRESQL_BIN=/usr/lib/postgresql/9.3/bin/postgres
POSTGRESQL_CONFIG_FILE=/etc/postgresql/9.3/main/postgresql.conf
POSTGRESQL_DATA=/var/lib/postgresql/9.3/main

POSTGRESQL_SINGLE="sudo -u postgres $POSTGRESQL_BIN --single \
                   --config-file=$POSTGRESQL_CONFIG_FILE"

if [ ! -d $POSTGRESQL_DATA ]; then
mkdir -p $POSTGRESQL_DATA
chown -R postgres:postgres $POSTGRESQL_DATA
sudo -u postgres /usr/lib/postgresql/9.3/bin/initdb \
                 -D $POSTGRESQL_DATA -E 'UTF-8'
fi

$POSTGRESQL_SINGLE <<< "CREATE USER $POSTGRESQL_USER WITH SUPERUSER;" \
  > /dev/null

$POSTGRESQL_SINGLE <<< "ALTER USER $POSTGRESQL_USER WITH PASSWORD
                       '$POSTGRESQL_PASS';" > /dev/null

$POSTGRESQL_SINGLE <<< "CREATE DATABASE $POSTGRESQL_DB OWNER
                        $POSTGRESQL_USER TEMPLATE
                        $POSTGRESQL_TEMPLATE;" > /dev/null

exec sudo -u postgres $POSTGRESQL_BIN \
                      --config-file=$POSTGRESQL_CONFIG_FILE
{% endhighlight %}

No script temos algumas variáveis ambiente para criar um banco, usuário e
senha default, caso essas informações não sejam passadas na criação do
container, então `POSTGRESQL_DB` cria um banco de dados automaticamente
caso não exista, `POSTGRESQL_USER` cria um usuário com acesso ao banco
especificado em `POSTGRESQL_DB` e em `POSTGRESQL_PASS` teremos a senha
para este usuário. Todos recebem o nome **docker** por padrão.

Criando a imagem utilizando o Dockerfile:

{% highlight bash %}
$ docker build -t ex_postgresql .
{% endhighlight %}

### Criando e acessando o container

Agora que a imagem foi gerada, podemos criar o nosso container e acessar
o PostgreSQL pelo host:

{% highlight bash %}
$ docker run -d -p 5432:5432 \
  -e POSTGRESQL_USER=test \
  -e POSTGRESQL_PASS=test123 \
  -e POSTGRESQL_DB=test \
  ex_postgresql
{% endhighlight %}

Durante a criação do container estou passando valores as variáveis do
script de inicialização, agora poderei ter acesso ao postgres que está
em execução no container partindo do host:

{% highlight bash %}
$ psql -h localhost -U test test
Password for user test:
psql (9.3.3, server 9.3.5)
SSL connection (cipher: DHE-RSA-AES256-SHA, bits: 256)
Type "help" for help.

test=#
{% endhighlight %}

Claro que o acesso pode ser feito utilizando o ip privado do container,
neste caso:

{% highlight bash %}
$ docker ps -q
1b8f91a297a8
$ docker inspect 1b8f91a297a8 | grep IPAddress
        "IPAddress": "172.17.0.9"
$ psql -h 172.17.0.9 -U test test
Password for user test:
psql (9.3.3, server 9.3.5)
SSL connection (cipher: DHE-RSA-AES256-SHA, bits: 256)
Type "help" for help.

test=#
{% endhighlight %}

No post sobre [gerar uma imagem docker para um projeto rails](http://infoslack.com/linux/construindo-uma-imagem-docker-para-aplicacoes-rails/), eu havia
criado um container para executar a aplicação, agora podemos fazer uma
pequena integração entre os containers, neste caso basta alterar o `database.yml`
do projeto e passar o ip do nosso container postgres:

{% highlight yaml %}
production:
  adapter: postgresql
  encoding: unicode
  pool: 5
  username: test
  password: test123
  host: 172.17.0.9
  port: 5432
  database: test
{% endhighlight %}

Além dos containers manterem uma comunicação entre si, estão liberando
acesso pelas portas definidas na criação, no caso a `80` no container onde
a aplicação existe e a `5432` no container do postgresql.

### Manipulando volumes

Durante a criação do container o volume `/var/lib/postgresql` foi exposto,
isso significa que os dados do postgresql serão persistidos nesse diretório
dentro do container, podemos ter acesso a esses dados utilizando a opção
`--volumes-from`:

{% highlight bash %}
$ docker run -d --volumes-from 340c8f4450a0 --name db-test ex_postgresql
{% endhighlight %}

Desta forma estaremos criando um novo container mapeando o acesso ao volume
do container onde o postgresql está rodando, podemos verificar se os arquivos
realmente estão sendo persistidos no novo container:

{% highlight bash %}
$ docker run -it --volumes-from 340c8f4450a0 \
                 --name db-test ex_postgresql /bin/bash
root@4a691f90f11a:/# ll /var/lib/postgresql/9.3/main/
total 68
drwx------ 15 postgres postgres 4096 Oct 18 15:48 ./
drwxr-xr-x  3 postgres postgres 4096 Oct 18 13:37 ../
-rw-------  1 postgres postgres    4 Oct 18 13:37 PG_VERSION
drwx------  7 postgres postgres 4096 Oct 18 15:48 base/
drwx------  2 postgres postgres 4096 Oct 18 15:49 global/
drwx------  2 postgres postgres 4096 Oct 18 13:37 pg_clog/
drwx------  4 postgres postgres 4096 Oct 18 13:37 pg_multixact/
drwx------  2 postgres postgres 4096 Oct 18 15:48 pg_notify/
drwx------  2 postgres postgres 4096 Oct 18 13:37 pg_serial/
drwx------  2 postgres postgres 4096 Oct 18 13:37 pg_snapshots/
drwx------  2 postgres postgres 4096 Oct 18 15:48 pg_stat/
drwx------  2 postgres postgres 4096 Oct 18 15:52 pg_stat_tmp/
drwx------  2 postgres postgres 4096 Oct 18 13:37 pg_subtrans/
drwx------  2 postgres postgres 4096 Oct 18 13:37 pg_tblspc/
drwx------  2 postgres postgres 4096 Oct 18 13:37 pg_twophase/
drwx------  3 postgres postgres 4096 Oct 18 13:37 pg_xlog/
-rw-------  1 postgres postgres   94 Oct 18 15:48 postmaster.opts
root@4a691f90f11a:/#
{% endhighlight %}

Agora que temos acesso ao volume do container postgresql, podemos trabalhar
com backups:

{% highlight bash %}
$ docker run --volumes-from 340c8f4450a0 -v $(pwd):/backup ex_postgresql \
             tar cvf /backup/backup.tar /var/lib/postgresql
{% endhighlight %}

Com isso estamos criando um novo container que terá acesso ao volume do
postgresql e executará uma instrução copiando os arquivos para o diretório
`/backup`, em seguida irá compactar no formato `tar` e por último o arquivo
`backup.tar` será disponibilizado no host.

Para executar um restore do backup feito em um novo container, podemos
primeiro criar um novo container com base na imagem do postgresql,
opcionalmente, podemos informar o novo volume com `-v`:

{% highlight bash %}
$ docker run -v /var/lib/postgresql --name test2 ex_postgresql /bin/bash
{% endhighlight %}

Em seguida podemos restaurar o backup no container `test2` que foi criado:

{% highlight bash %}
$ docker run --volumes-from test2 -v $(pwd):/backup busybox \
             tar xvf /backup/backup.tar
{% endhighlight %}

Se preferir confira o projeto [docker-backup](https://github.com/docker-infra/docker-backup) para automatizar esse processo.

### Finalizando

Continuarei explorando o Docker tanto no ambiente de desenvolvimento quanto
em produção, em futuros posts trarei mais novidades.

Estou disponibilizando o Dockerfile criado neste post aqui:
[https://github.com/infoslack/docker-postgresql](https://github.com/infoslack/docker-postgresql)

Happy Hacking ;)

### Referências

- [http://docs.docker.com/examples/postgresql_service/](http://docs.docker.com/examples/postgresql_service/)
- [http://docs.docker.com/userguide/dockervolumes/](http://docs.docker.com/userguide/dockervolumes/)
- [https://github.com/docker-infra/docker-backup](https://github.com/docker-infra/docker-backup)
- [https://github.com/infoslack/docker-postgresql](https://github.com/infoslack/docker-postgresql)
