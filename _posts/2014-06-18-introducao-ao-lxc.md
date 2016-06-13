---
layout: post
title: "Introdução ao LXC (LinuX Containers)"
description: "Conheça o LXC LinuX Containers, uma alternativa a virtualização"
category: linux
keywords: linux, kernel, virtualização, lxc, heroku, dyno, container, modulo
---

### Introdução

[LXC (LinuX Containers)](https://linuxcontainers.org/) é um tipo de virtualização em nível de sistema
operacional que proporciona a execução de vários sistemas Linux de forma
isolada (containers) em um único host de controle. Em outras palavras é uma
alternativa para virtualização completa e leve se comparada aos [hypervisors
KVM, Xen e VMware](http://en.wikipedia.org/wiki/Hypervisor).

O Kernel Linux possui o recurso [Cgroups](http://en.wikipedia.org/wiki/Cgroups) que é utilizado para limitar e
isolar o uso de (*CPU*, *memória*, *disco*, *rede*, etc) e também o isolamento de
**namespace** que basicamente separa grupos de processos de modo que eles não
enxerguem os recursos de outros grupos, ou seja:

![Linux Cgroups](/images/lxc.png)

Antes de continuar, vamos relembrar sobre os tipos de virtualização
(*bare metal* e *hosted*).

O tipo bare metal, o software que proporciona a virtualização é instalado
diretamente sobre o hardware:(*Xen*, *VMware*, *Hyper-V*), esse tipo proporciona um
isolamento maior e ao mesmo tempo uma sobrecarga pois cada máquina virtual que
é criada irá executar seu próprio kernel e instância do sistema operacional.

Já o tipo hosted, o software que proporciona a virtualização é executado sobre
um sistema operacional:(*VirtualBox*).

A virtualização por containers proposta pelo LXC ocorre de forma menos isolada
pois compartilha algumas partes do kernel do host fazendo com que a sobrecarga
seja menor.

### Testando

Durante os testes que fiz utilizei uma instância na Amazon com (*Ubuntu 14.04LTS
64 bits*), a instalação do LXC é bem simples no ubuntu:

```bash
ubuntu@heroku:~$ sudo apt-get install lxc
```

Depois de instalado vamos para a criação do nosso primeiro container, para isso
usaremos o comando `lxc-create`:

```bash
ubuntu@heroku:~$ sudo lxc-create -t ubuntu -n dyno-01
```

O parâmetro `-t` especifica o template que usaremos para criar o container, no
caso estou especificando o Ubuntu, por padrão o LXC utiliza a última versão LTS.
O `-n` determina um nome para o nosso container.

Após finalizar a criação do container, podemos listar com `lxc-ls` que retorna
todos os containers criados, para verificar o atual estado de execução podemos
usar o comando `lxc-info`:

```bash
ubuntu@heroku:~$ sudo lxc-ls
dyno-01
ubuntu@heroku:~$ sudo lxc-info -n dyno-01
Name:    dyno-01
State:   STOPPED
ubuntu@heroku:~$
```

Agora que criamos o nosso container, podemos iniciá-lo com `lxc-start`:

```bash
ubuntu@heroku:~$ sudo lxc-start -d -n dyno-01
ubuntu@heroku:~$ sudo lxc-info -n dyno-01
Name:           dyno-01
State:          RUNNING
PID:            5986
IP:             10.0.3.69
CPU use:        2.54 seconds
BlkIO use:      100.00 KiB
Memory use:     7.89 MiB
Link:           vethPTIYBW
 TX bytes:      2.02 KiB
 RX bytes:      2.04 KiB
 Total bytes:   4.07 KiB
ubuntu@heroku:~$
```

A opção `-d` que utilizei foi para executar o container em segundo plano, dessa
forma ele não assume o console e assim podemos nos conectar a ele com
`lxc-console`:

```bash
ubuntu@heroku:~$ sudo lxc-console -n dyno-01
ubuntu@dyno-01:~$
```

Nesse momento entramos no container `dyno-01` e tudo o que for executado nele
será de forma isolada do sistema operacional, podemos por exemplo instalar uma
versão de Ruby em `dyno-01` e verificar o que acontece no host:

```bash
ubuntu@dyno-01:~$ sudo apt-get install wget
ubuntu@dyno-01:~$ wget http://apt.hellobits.com/hellobits.key
ubuntu@dyno-01:~$ sudo apt-key add hellobits.key
ubuntu@dyno-01:~$ echo 'deb http://apt.hellobits.com/ trusty main' |\
> sudo tee /etc/apt/sources.list.d/hellobits.list
ubuntu@dyno-01:~$ sudo apt-get update && sudo apt-get install ruby-2.1
ubuntu@dyno-01:~$ ruby -v
ruby 2.1.2p95 (2014-05-08 revision 45877) [x86_64-linux]
ubuntu@dyno-01:~$ exit
```

Para sair do console do container execute `Ctrl + a` e tecle `q`, agora podemos
ver o que aconteceu no host:

```bash
ubuntu@heroku:~$ ruby -v
The program 'ruby' can be found in the following packages
```

O ruby que instalamos existe apenas no nosso container `dyno-01`, nada foi
afetado no nosso host.

Podemos congelar e descongelar containers criados com `lxc-freeze` e
`lxc-unfreeze`:

```bash
ubuntu@heroku:~$ sudo lxc-freeze -n dyno-01
ubuntu@heroku:~$ sudo lxc-info -n dyno-01 | grep State
State:      FROZEN
ubuntu@heroku:~$ sudo lxc-unfreeze -n dyno-01
ubuntu@heroku:~$ sudo lxc-info -n dyno-01 | grep State
State:      RUNNING
```

É interessante notar a velocidade de execução dessas ações no container.

Outro recurso interessante é o de clonagem, onde podemos fazer uma cópia de um
container já existente e atribuir um nome diferente, para isso usamos o
`lxc-clone`:

```bash
ubuntu@heroku:~$ sudo lxc-clone -o dyno-01 -n dyno-02
Created container dyno-02 as copy of dyno-01
ubuntu@heroku:~$ sudo lxc-ls
dyno-01  dyno-02
ubuntu@heroku:~$
```

Como o container `dyno-02` é um clone de `dyno-01` a instalação do ruby feita
anteriormente consta no novo container:

```bash
ubuntu@heroku:~$ sudo lxc-console -n dyno-02
ubuntu@dyno-02:~$ ruby -v
ruby 2.1.2p95 (2014-05-08 revision 45877) [x86_64-linux]
```

Até aqui vimos como operar o LXC, veremos agora um pouco de configuração.
Por padrão o LXC organiza os containers em `/var/lib/lxc`, cada container
criado possui um diretório com seus arquivos de configuração:

```bash
ubuntu@heroku:~$ sudo ls /var/lib/lxc
dyno-01  dyno-02
ubuntu@heroku:~$ sudo ls /var/lib/lxc/dyno-01
config  fstab  rootfs
ubuntu@heroku:~$
```

Para o próximo exemplo, vamos configurar o container `dyno-01` para que o uso
de memória dele seja limitado a 512MB, para isso edite o arquivo `config`
localizado em `/var/lib/lxc/dyno-01` e adicione a seguinte instrução ao final
do arquivo:

```bash
ubuntu@heroku:~$ suco echo "lxc.cgroup.memory.limit_in_bytes = 512M" >> \
> /var/lib/lxc/dyno-01/config
```

Em seguida reinicie o container em modo de debug para verificarmos o consumo
de memória feito por `dyno-01`:

```bash
ubuntu@heroku:~$ sudo lxc-stop -n dyno-01
ubuntu@heroku:~$ sudo lxc-start -d -n dyno-01 -l debug -o dyno01.out
ubuntu@heroku:~$ cat dyno01.out | grep "memory.limit"

lxc-start 1403131667.309 DEBUG  lxc_cgmanager - \
cgroup 'memory.limit_in_bytes' set to '512M'
ubuntu@heroku:~$
```

Lembra do cgroups ? Pois é, o que fizemos foi dizer para o Kernel limitar o
uso de memória feito pelo container `dyno-01` a 512MB.

Agora podemos verificar quanta memória o nosso container está consumindo, isso
é possível pois o Kernel armazena essas informações em runtime:

```bash
$ sudo cat /sys/fs/cgroup/memory/lxc/dyno-01/memory.usage_in_bytes
7249920
$ expr 7249920 / 1024
7080
```

Ou seja 7080 Kb, dos 512 Mb que configuramos estão em uso.

### Conclusão

O que vimos foi a ponta do iceberg de como o [Heroku](https://www.heroku.com/) faz para criar e
controlar os [dynos](https://devcenter.heroku.com/articles/dynos).
O projeto [Docker](http://www.docker.com/) também faz uso do LXC em seu back-end.

A quantidade de opções de configuração são gigantes e merecem um estudo
profundo, espero que tenha gostado desta pequena apresentação.

Happy Hacking ;)

### Referências

- [https://linuxcontainers.org/](https://linuxcontainers.org/)

- [http://en.wikipedia.org/wiki/LXC](http://en.wikipedia.org/wiki/LXC)

- [http://en.wikipedia.org/wiki/Cgroups](http://en.wikipedia.org/wiki/Cgroups)

- [https://help.ubuntu.com/lts/serverguide/lxc.html](https://help.ubuntu.com/lts/serverguide/lxc.html)

- [http://www.mjmwired.net/kernel/Documentation/cgroups/memory.txt](http://www.mjmwired.net/kernel/Documentation/cgroups/memory.txt)

- [https://devcenter.heroku.com/articles/dynos](https://devcenter.heroku.com/articles/dynos)
