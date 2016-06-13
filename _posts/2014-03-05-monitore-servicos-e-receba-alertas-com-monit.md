---
layout: post
title: "Monitore serviços e receba alertas com monit"
description: "Fique de olho nos serviços e receba alertas no seu e-mail, use Monit"
category: devops
keywords: server, linux, unix, services, servidor, monit, alertas, serviços, devops
---

### Introdução

[Monit](http://mmonit.com/monit/) é uma ferramenta open source que gerencia e
monitora, aplicações, processos, arquivos, etc em sistemas Unix ou [Unix-like](http://en.wikipedia.org/wiki/Unix-like).
Além disso, **monit** pode realizar reparos automáticos e executar ações em
ocorrências de erro no sistema, por exemplo, restartar um serviço que teve falha
repentina ou enviar e-mail de alerta avisando sobre algum erro.

No exemplo a seguir, precisamos monitorar o [Nginx](http://nginx.org/) e caso o
serviço seja parado por qualquer motivo o **monit** deve nos enviar um e-mail
de alerta informando sobre o incidente.

### Instalação e Configuração

No exemplo estou monitorando uma instância Amazon EC2 com Ubuntu 12.04 LTS,
assumindo que o Nginx está instalado e funcionando, vamos ao trabalho:

```bash
$ sudo apt-get install monit
```

A configuração default do monit fica em `/etc/monit`, temos o `monitrc` que é
o arquivo de configuração principal e o diretório `conf.d` que  armazena as
configurações dos serviços que queremos ficar de olho.

No nosso exemplo vamos ficar de olho no *nginx*, então crie um arquivo chamado
*nginx.conf* no diretório *conf.d*:

```bash
$ touch /etc/monit/conf.d/nginx.conf
```

A sintaxe do monit é bem simples e muito legível:

```powershell
set alert infoslack@gmail.com

check host 54.186.55.68 with address 54.186.55.68
    if failed host 54.186.55.68 port 80 then alert

set mailserver smtp.gmail.com port 587
    username "login-gmail" password "password"
    using tlsv1
    with timeout 30 seconds
```

Vamos por partes:

* `set alert` estou informando o e-mail onde quero receber os alertas;
* `check host` quero que o monit fique verificando o host que pode ser ip/domínio;
* `if failed` em caso de falha ele deve executar uma ação, no caso o alerta;
* `set mailserver` configura o server de smtp para envio de e-mails;

Gosto de usar o *Gmail* para este serviço pois ter um servidor de *smtp* próprio
não é uma boa idéia por consumir recursos(processador/memória) do server, além
disso tem o risco do e-mail enviado cair no *Spam*.

No exemplo configurei o tempo que o monit leva para fazer a verificação do
**host**, essa configuração fica em `/etc/monit/monitrc` no parâmetro
`set daemon`, por default o valor é *120* segundos no meu caso deixei em *60*.

Depois de tudo configurado, basta testar parando o serviço do *nginx*, como
resultado deve chegar um alerta por e-mail informando sobre a falha:

![Alerta monit](/images/monit-alert-fail.png)

Ao iniciar o *nginx* novamente, o monit envia outro alerta avisando que o
serviço está funcionando novamente:

![Alerta monit](/images/monit-alert-success.png)

Outra configuração poderia ser feita para verificar o `PID` do *nginx*, ou seja
ficar de olho no processo do serviço e em caso de interrupção o próprio monit
executaria uma ação para iniciar o serviço novamente e alertaria:

```powershell
check process nginx with pidfile /var/run/nginx.pid
    start program = "/etc/init.d/nginx start"
    stop program = "/etc/init.d/nginx stop"
    if failed host 54.186.55.68 port 80 then restart
```

### Finalizando

A [documentação do monit](http://mmonit.com/monit/documentation/monit.html) é muito rica e vale conferir outras opções como por
exemplo a formatação do layout do e-mail, as informações que serão enviadas no
alerta e até a configuração para utilizar a interface web.

Use e abuse da criatividade ;)
