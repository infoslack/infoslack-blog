---
layout: post
title: "Automatize tarefas com monit"
description: "Deixe o monit trabalhar por você, automatize as tarefas"
category: devops
keywords: server, linux, unix, services, servidor, monit, alertas, serviços, devops
---

Este é um complemento do [post anterior](http://infoslack.com/server/monitore-servicos-e-receba-alertas-com-monit/) sobre monit e veremos como podemos automatizar
tarefas rotineiras.

No exemplo tenho uma aplicação Ruby on Rails e preciso restartar o meu servidor
de aplicações [Unicorn](http://unicorn.bogomips.org/) a cada deploy. Para isso
o monit deve ficar de olho na minha aplicação aguardando que a mesma sofra
alterações após o processo de deploy e em seguida execute uma ação, no nosso
caso reiniciar o *Unicorn*.

Tenho um arquivo de [upstart](http://upstart.ubuntu.com/) com instruções para inicializar o *Unicorn* e
dar o start na minha aplicação:

{% highlight powershell %}
description "rails_app server config"

pre-start script
  mkdir -p /var/log/unicorn
  chown www-data. /var/log/unicorn

  mkdir -p /var/run/unicorn
  chown www-data. /var/run/unicorn
end script

start on runlevel [23]
stop on shutdown

exec sudo -u www-data sh -c "cd /var/www/rails_app/current && \
bundle exec unicorn -c /etc/unicorn/rails_app.conf"

respawn
{% endhighlight %}

Com o *upstart* posso executar chamadas para minha aplicação `sudo (start|stop|restart) rails_app`
sendo assim, agora posso explicar para o monit o que ele deve fazer.
A cada deploy executado, o comando `touch` será executado para criar um arquivo
chamado *restart.txt*, sempre que o touch é executado o arquivo gerado sofre
alteração em seu [timestamp](http://en.wikipedia.org/wiki/Timestamp) é justamente com base nisso que o monit vai saber
quando executar a ação de restart.

Nossa configuração do monit ficará assim:

{% highlight powershell %}
check file restart.txt with path /var/www/rails_app/shared/restart.txt
  if changed timestamp
    then exec "/usr/sbin restart rails_app"
{% endhighlight %}

O monit vai ficar de olho no arquivo *restart.txt* no diretório
`/var/www/rails_app/shared` e sempre que ele sofrer alteração em seu timestamp
a cada novo deploy, a ação de restart será executada.

Happy Hacking ;)
