---
layout: post
title: "Replicação Master-Slave com PostgreSQL e Rails"
description: "Utilize o PostgreSQL com replicação Master-Slave em projetos Rails"
category: development
keywords: rails4, postgresql, replication, desenvolvimento, master, slave, octopus
---

Imagine que você tenha uma aplicação Rails em produção que recebe muitas consultas
e cadastros diariamente, no projeto inicial uma única instância para o banco
de dados era suficiente, após ocorrer alguns problemas de lentidão você
fez uma refatoração gigante para eliminar as consultas mais lentas e isso
resolveu o problema por um tempo.

Bem, a aplicação está maior, o número de usuários também aumentou bastante
e você percebeu o problema de ter as operações de leitura e escrita numa
única instância para o banco, agora é hora de redimensionar a infra.

### Replicando o PostgreSQL

A ideia inicial é configurar o Postgres de forma que você tenha 2 instâncias
separadas, uma `master` que será a read-write e outra `slave` para read-only.

Para ajustar o servidor que será tratado como master, podemos criar um
usuário com permissões para replicação:

{% highlight bash %}
$ sudo -u postgres psql -c \
"CREATE USER replicator REPLICATION LOGIN ENCRYPTED PASSWORD 'xpto123';"
{% endhighlight%}

Em seguida configurar os parâmetros para streaming replication, editando
o arquivo `/etc/postgresql/9.3/main/postgresql.conf`:

{% highlight text %}
listen_address = '192.168.50.5'
wal_level = hot_standby
max_wal_senders = 3
checkpoint_segments = 8
wal_keep_segments = 8
{% endhighlight%}

No exemplo estou informando que o ip da instância master é `192.168.50.5`
e que usaremos 8 segmentos de WAL de 16MB cada. Write-Ahead Logging (WAL)
que basicamente é um método para garantir a integridade dos dados.
Além desta configuração, ainda temos que permitir a conexão do `slave` ao
master, para isso vamos editar o arquivo: `/etc/postgresql/9.3/main/pg_hba.conf`:

{% highlight text %}
host   replication   replicator  192.168.50.10   md5
{% endhighlight%}

Aqui estou dizendo que `192.168.50.10` é o server slave e que ele tem permissão
para estabelecer conexão com o master utilizando o usuário que criamos no
primeiro passo, agora que tudo está ajustado, podemos restartar o Postgre
master.

### Configurando o slave

Na instância que será usada para slave, só precisamos alterar 1 arquivo,
`/etc/postgresql/9.3/main/postgresql.conf` e informar que ele deve operar
no esquema de replicação:

{% highlight text %}
wal_level = hot_standby
max_wal_senders = 3
checkpoint_segments = 8
wal_keep_segments = 8
hot_standby = on
{% endhighlight%}

Feito isso só precisamos dizer ao slave que ele deve clonar o master:

{% highlight bash %}
$ sudo -u postgres pg_basebackup \
-h 192.168.50.5 -D /data -U replicator -v -P
{% endhighlight%}

Ao executar isso estou dizendo ao slave que ele deve fazer um clone do
master, utilizando o usuário replicator. Na opção `-D /data` estou informando
o diretório onde os arquivos da base clonada do master serão armazenados,
por default o diretório é: `/var/lib/postgresql/9.3/main/`, eu prefiro utilizar
um mais fácil ;)

Antes de inicializar o postgres slave, precisamos criar um arquivo chamado
`recovery.conf` que ficará dentro de `/data` ele armazena os parâmetros que
serão utilizados pelo postgresql sempre que o slave for reiniciado:

{% highlight text %}
standby_mode = 'on'
primary_conninfo = 'host=192.168.50.5 port=5432 \
                   user=replicator password=xpto123'
trigger_file = '/tmp/postgresql.trigger'
{% endhighlight%}

Agora o slave pode ser iniciado:

{% highlight bash %}
$ sudo service postgresql start
{% endhighlight%}

E no master podemos verificar se a replicação ocorreu sem problemas:

{% highlight bash %}
$ sudo -u postgres psql -x -c "select * from pg_stat_replication;"

-[ RECORD 1 ]----+------------------------------
pid              | 6822
usesysid         | 16384
usename          | replicator
application_name | walreceiver
client_addr      | 192.168.50.10
client_hostname  | pg_slave
client_port      | 52893
backend_start    | 2014-10-12 21:09:52.491779+00
state            | streaming
sent_location    | 0/6001018
write_location   | 0/6001018
flush_location   | 0/6001018
replay_location  | 0/6001018
sync_priority    | 0
sync_state       | async
{% endhighlight%}

### Configurando o Rails para trabalhar com a replicação

Agora que o PostgreSQL foi ajustado para trabalhar com  replicação
master-slave, podemos dizer ao Rails para executar as operações de escrita
no `master` e as de leitura no `slave`.

Das muitas opções existentes eu estou gostando de utilizar o [Octopus](https://github.com/tchandy/octopus),
pois além de resolver bem os problemas, a sua configuração é bastante simples.
Para iniciar, basta adicionar a gem `ar-octopus` no Gemfile do projeto:

{% highlight ruby %}
...
gem "rails", "4.1.6"
gem "pg"
gem "ar-octopus"
...
{% endhighlight%}

Em seguida, precisamos criar o arquivo `config/shards.yml` para informar
as diretivas do nosso server slave:

{% highlight yaml %}
octopus:
  replicated: true

  production:
    slave1:
      adapter: postgresql
      encoding: unicode
      pool: 5
      username: userapp
      password: passapp
      host: 192.168.50.10
      port: 5432
      database: myapp
{% endhighlight%}

Desta forma o Octopus vai enviar todas as operações de leitura para o slave,
já as configurações para operações de escrita no master serão lidas do database.yml:

{% highlight yaml %}
production:
  adapter: postgresql
  encoding: unicode
  pool: 5
  username: userapp
  password: passapp
  host: 192.168.50.5
  port: 5432
  database: myapp
{% endhighlight%}

Agora temos o poder de escolher que operações nossa aplicação pode fazer
e em qual banco ela deve fazer, por exemplo, a consulta para exibir todos
os posts pode ser feita no slave:

{% highlight ruby %}
class PostsController < ApplicationController

def index
  @posts = Post.using(:slave1).all
end
...
{% endhighlight%}

Ou podemos mandar toda e qualquer operação de escrita para o master e de
leitura para slave, utilizando o método `#replicated_model` nos modelos:

{% highlight ruby %}
class Post < ActiveRecord::Base
  replicated_model
end
{% endhighlight%}

### Conclusão

Está é apenas uma das muitas formas de distribuir a sua aplicação para trabalhar
com bases de dados replicadas. O Octopus suporta o uso de [sharding](http://en.wikipedia.org/wiki/Shard_(database_architecture))
que permite **distribuir os dados** em várias instâncias.

Caso você tenha uma aplicação no Heroku e queira fazer algo parecido: [https://devcenter.heroku.com/articles/distributing-reads-to-followers-with-octopus](https://devcenter.heroku.com/articles/distributing-reads-to-followers-with-octopus)

Happy Hacking ;)

### Referências

- [http://www.postgresql.org/docs/9.3/static/wal-intro.html](http://www.postgresql.org/docs/9.3/static/wal-intro.html)
- [http://www.postgresql.org/docs/9.3/static/wal-configuration.html](http://www.postgresql.org/docs/9.3/static/wal-configuration.html)
- [http://www.postgresql.org/docs/9.3/static/different-replication-solutions.html](http://www.postgresql.org/docs/9.3/static/different-replication-solutions.html)
- [https://devcenter.heroku.com/articles/distributing-reads-to-followers-with-octopus](https://devcenter.heroku.com/articles/distributing-reads-to-followers-with-octopus)
- [https://github.com/tchandy/octopus](https://github.com/tchandy/octopus)
- [https://github.com/tchandy/octopus/wiki/replication](https://github.com/tchandy/octopus/wiki/replication)
