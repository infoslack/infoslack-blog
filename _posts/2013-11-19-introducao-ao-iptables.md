---
layout: post
title: "Introdução ao iptables"
category: security
keywords: linux, security, segurança, firewall
---

### O que é o iptables ?

[Netfilter](http://netfilter.org/) é o firewall padrão embutido no kernel linux,
sua função é tratar regras aplicadas a pacotes TCP-IP.
O [iptables](http://www.netfilter.org/projects/iptables/) nada mais é que uma interface controladora do Netfilter.

### Entendendo as regras

Para gerenciar o tratamento das regras e aplicar aos pacotes o iptables conta
com tabelas e chains.

As tabelas servem para armazenar as chains. Chains são regras para especificar
o tratamento dos pacotes.

O iptables possuí 4 tabelas:

* **nat** - tabela padrão usada quando existe comunicação [NAT](http://en.wikipedia.org/wiki/Network_address_translation);
* **filter** - tabela padrão para tráfego de dados comum com NAT;
* **mangle** - tabela para regras especiais de pacotes;

A tabela `filter` é composta pelas seguintes chains:

* **INPUT** - define regras de entrada de pacotes;
* **OUTPUT** - são regras para saída de pacotes;
* **FORWARD** - regras para pacotes que passam pelo firewall;

Já as chains da tabela `nat` são:

* **PREROUTING** - regra para processar pacotes antes do roteamento feito pelo firewall;
* **POSTROUTING** - regra para processar pacotes depois do roteamento feito pelo firewall;
* **OUTPUT** - regras para saída de pacotes;
<br>
### Aplicando regras e determinando ações

Das opções mais utilizadas para aplicar regras na sintaxe do iptables temos:

* `-s` serve para especificar a origem do pacote, EX: `-s 192.168.0.1`
* `-d` serve para especificar o destino do pacote, EX: `-d 192.168.0.5`
* `-i` serve para identificar a interface de entrada do pacote, EX: `-i eth0`
* `-o` serve para identificar a interface de saída do pacote, EX: `-o eth1`;
* `-p` serve para especificar o protocolo usado na regra, EX: `-p tcp` ou `-p udp`

Para definir as ações usa-se o parâmetro `-j`:

* **ACCEPT** - aceita o pacote e o processamento da regra é concluído;
* **DROP** - apenas rejeita o pacote;
* **REJECT** - rejeita o pacote e envia um aviso;
* **LOG** - envia mensagem para o `syslog` gravando informações sobre pacotes aceitos ou rejeitados;

As opções são muitas, para ver todas detalhadamente consulte a documentação.

Ao implementar as regras do firewall podemos e devemos adotar políticas. As políticas
são um conjunto de condições que definem o bloqueio ou a liberação de tráfego de dados.
No caso do iptables o parâmetro `-P` define isso.

No exemplo abaixo estou negando todo o tráfego para as regras de `INPUT`, `OUTPUT` e
`FORWARD` da tabela `filter` ou seja estou bloqueando todas as regras para entrada e
saída de pacotes na minha máquina.

{% highlight powershell %}
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
{% endhighlight %}

Para verificar regras que foram definidas usamos o parâmetro `-L` e para zerar
as regras `-R`.

{% highlight bash %}
$ iptables -L
Chain INPUT (policy DROP)
target     prot opt source               destination

Chain FORWARD (policy DROP)
target     prot opt source               destination

Chain OUTPUT (policy DROP)
target     prot opt source               destination
{% endhighlight %}

Testando o firewall, podemos dar um ping na nossa máquina:

{% highlight bash %}
$ ping localhost
PING localhost (127.0.0.1) 56(84) bytes of data.
ping: sendmsg: Operation not permitted
{% endhighlight %}

Como a política foi escrita para negar tudo, vamos definir uma exceção para nossa
própria máquina liberando o tráfego de pacotes para a interface [loopback](http://en.wikipedia.org/wiki/Loopback):

{% highlight powershell %}
iptables -A OUTPUT -d 127.0.0.1 -j ACCEPT
iptables -A INPUT -d 127.0.0.1 -j ACCEPT
{% endhighlight %}

Agora se efetuarmos o mesmo teste anterior é possível obter resposta do ping:

{% highlight bash %}
$ ping localhost
PING localhost (127.0.0.1) 56(84) bytes of data.
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.036 ms
64 bytes from localhost (127.0.0.1): icmp_seq=2 ttl=64 time=0.043 ms
...
{% endhighlight %}

Um exemplo de script simples de iptables poderia ser assim:

{% highlight powershell %}
#!/bin/bash

# definindo política padrão
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# configurações para regras de entrada
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
{% endhighlight %}

Basicamente as regras de `INPUT` e `FORWARD` estão bloqueadas e tudo o que sair
da máquina será liberado.

### Concluindo

O que vimos é o básico, uma parte teórica do funcionamento do iptables,
existe uma infinidade de outros comandos e muitas opções que podem ser exploradas.

Em servidores gosto de soluções mais práticas para configurar o iptables,
como é o caso do [UFW (Uncomplicated Firewall)](https://help.ubuntu.com/community/UFW)
que basicamente funciona como uma interface amigável na linha de comando para
gerar as regras do iptables.
