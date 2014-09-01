---
layout: post
title: "Primeiros passos com Docker"
category: linux
keywords: linux, kernel, virtualização, lxc, docker, container, modulo, PAAS, SaaS
---

[Docker](https://www.docker.com/) é um projeto open-source escrito em [Go](http://golang.org/) que facilita a criação de
containers portáteis e leves, ou seja, o mesmo container criado em ambiente
de desenvolvimento ou de testes pode funcionar perfeitamente em produção. Ele
faz uso do [LXC](https://linuxcontainers.org/) em seu back-end.

### Containers vs VMS

Apenas para relembrar o que falei neste outro post: [Introdução ao LXC](http://infoslack.com/linux/introducao-ao-lxc/),
VMS necessitam de uma imagem completa de um sistema operacional e todos os
recursos alocados para funcionar, além disso o tempo para inicializar é longo.

Containers são mais leves, já que não precisam de um ambiente virtual completo,
pois o kernel do host proporciona total gerenciamento de memória, I/O, cpu, etc.
Isso significa que a inicialização leva poucos segundos.

### Setup

Instalar e começar a usar é muito simples, nos testes utilizei uma máquina Ubuntu
14.04 na Amazon:

{% highlight bash %}
$ sudo apt-get update && upgrade
$ sudo apt-get install build-essentials python-software-properties git
$ sudo sh -c "wget -qO- https://get.docker.io/gpg | apt-key add -"
$ sudo sh -c "echo deb http://get.docker.io/ubuntu docker main\
> /etc/apt/sources.list.d/docker.list"
$ sudo apt-get update
$ sudo apt-get install lxc-docker
{% endhighlight %}
<p></p>
### It Works

Para o primeiro exemplo, vamos criar um container e pedir para ele executar
algum comando:

{% highlight bash %}
$ sudo docker run ubuntu /bin/echo It Works!
Unable to find image 'ubuntu' locally
Pulling repository ubuntu
c4ff7513909d: Download complete
511136ea3c5a: Download complete
1c9383292a8f: Download complete
9942dd43ff21: Download complete
d92c3c92fa73: Download complete
0ea0d582fd90: Download complete
cc58e55aa5a5: Download complete
It Works!
$
{% endhighlight %}

O que aconteceu foi que o *Docker* fez um download de uma imagem base, no caso
do *Ubuntu*, depois instanciou um novo container LXC, configurou a interface de
rede e escolheu um ip, selecionou um sistema de arquivos para o novo container,
por fim executou o comando `/bin/echo` e capturou sua saída.

### Um pouco de interatividade

O Docker é bastante interativo com os containers, por exemplo, podemos verificar
se existe algum container em execução com o comando `docker ps`:

{% highlight bash %}
$ sudo docker ps
CONTAINER ID   IMAGE  COMMAND   CREATED   STATUS  PORTS   NAMES
$
{% endhighlight %}

Como não temos nenhum container em execução, vamos para um exemplo mais real,
instalar o Nginx usando um shell interativo no container:

{% highlight bash %}
$ sudo docker run -i -t ubuntu /bin/bash
root@1cfd4d5a1812:/# apt-get update && apt-get upgrade -y
root@1cfd4d5a1812:/# apt-get install wget
root@1cfd4d5a1812:/# wget -q -O - http://nginx.org/keys/nginx_signing.key\
> | apt-key add -
root@1cfd4d5a1812:/# echo 'deb http://nginx.org/packages/ubuntu/ trusty nginx'\
> | tee /etc/apt/sources.list.d/nginx.list
root@1cfd4d5a1812:/# apt-get update && apt-get install nginx
root@1cfd4d5a1812:/# nginx -v
nginx version: nginx/1.6.1
root@1cfd4d5a1812:/# exit
{% endhighlight %}

Uma instalação padrão do Nginx foi feita, agora precisamos commitar o container
e salvar o estado de tudo o que foi feito, essa é a beleza do Docker ;)

{% highlight bash %}
$ sudo docker commit 1cfd4d5a1812 infoslack/nginx
93f3780db290b6e0d0b718b6488574d95e4fdeaecc3b91ae314b5653459ab73a
$
{% endhighlight %}
<p></p>
### Um pouco de automação com Dockfile

Podemos escrever um arquivo *Dockfile* para automatizar o processo de criação
de uma imagem, informando as tarefas que devem ser executadas no build:

{% gist infoslack/431ed1a457aab055b423 %}

Agora só precisamos gerar a nova imagem e criar o novo container:


{% highlight bash %}
$ sudo docker build -t nginx_img_1 .
$ sudo docker run --name nginx_container -p 80:80 -d -t nginx_img_1
{% endhighlight %}

O parâmetro `--name` estou descrevendo o nome do container que será criado e o
`-p 80:80` está mapeando a porta 80 do container para a porta 80 do host. Podemos
testar com o *curl*, enviando um request para o ip público da instância EC2:

{% highlight bash %}
$ curl -IL http://54.68.7.88/
HTTP/1.1 200 OK
Server: nginx/1.6.1 (Ubuntu)
Date: Mon, 01 Sep 2014 03:22:39 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 04 Mar 2014 11:46:45 GMT
Connection: keep-alive
ETag: "5315bd25-264"
Accept-Ranges: bytes
$
{% endhighlight %}

Agora é possível listar o processo do container em execução:

{% highlight bash %}
$ sudo docker ps
CONTAINER ID  IMAGE               COMMAND              CREATED        STATUS        PORTS              NAMES
863e3fa2ed3f  nginx_img_01:latest "/bin/sh -c "service 24 minutes ago Up 24 minutes 0.0.0.0:80->80/tcp nginx_cont_1
{% endhighlight %}

Docker é muito poderoso e vale explorar as suas facilidades!

Happy Hacking ;)

### Referências

- [https://www.docker.com/](https://www.docker.com/)

- [https://github.com/docker/docker](https://github.com/docker/docker)

- [https://docs.docker.com/](https://docs.docker.com/)
