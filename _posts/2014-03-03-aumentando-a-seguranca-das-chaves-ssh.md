---
layout: post
title: "Aumentando a segurança das chaves ssh"
description: "Aumente a segurança da sua conexão ssh, turbinando a criptografia de suas chaves"
category: security
keywords: security, hacking, segurança, invasão, server, ssh, keys, openssh
---

Depois de quase 4 anos utilizando um par de chaves DSA de 1024 bits, resolvi
finalmente atualizar para RSA, eu vinha evitando o update por preguiça pois
teria que substituir as chaves em muitos lugares (github, bitbucket, vps, servers...).

Pois bem, ao criar um par de chaves RSA o OpenSSH por default gera chaves de
2048 bits, não tenho mais certeza se isso é forte o suficiente uma vez que a
[NSA pode quebrar chaves RSA de 1024 bits](http://arstechnica.com/security/2013/09/of-course-nsa-can-crack-crypto-anyone-can-the-question-is-how-much/)
em questão de horas, melhor não esperar para saber se mais alguém pode conseguir o mesmo.

Pensando nisso resolvi gerar novas chaves RSA usando 4096 bits, achei que
ficaria um pouco lento mas não atrapalhou em nada, 2 centésimos de segundo no
meu uso não faz diferença.

{% highlight bash %}
$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (~/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in ~/.ssh/id_rsa.
Your public key has been saved in ~/.ssh/id_rsa.pub.
The key fingerprint is:
98:50:29:f1:15:1a:42:3c:76:9f:5e:c9:2b:26:ce:8d infoslack@l33t
The keys randomart image is:
+--[ RSA 4096]----+
|   o+.o.o.       |
|    =+o+         |
|   ..+o. o .     |
|     . oo +      |
|      o.S. .     |
|      . + .      |
|     o = .       |
|      E .        |
|                 |
+-----------------+
$
{% endhighlight %}

Bem, antes de deixar de usar as antigas chaves DSA e removê-las do sistema de
uma vez, fiz um loop na minha lista de servers para atualizar o `authorized_keys`
de cada máquina:

{% highlight bash %}
$ for host in `cat ~/.ssh/config | grep '^Host ' | sed 's/Host //'`;
> do scp ~/configs/authorized_keys $host:.ssh/; done
$
{% endhighlight %}

Dessa forma atualizei a chave pública em todos os servers da minha lista, nos
outros serviços tive que fazer manualmente.

Segue abaixo alguns links para refletir sobre aumentar ou não a segurança de
suas chaves:

[Of course NSA can crack crypto.](http://arstechnica.com/security/2013/09/of-course-nsa-can-crack-crypto-anyone-can-the-question-is-how-much/)

[RSA 1024-bit private key encryption cracked](http://news.techworld.com/security/3214360/rsa-1024-bit-private-key-encryption-cracked/)

[Tor is still DHE 1024 (NSA crackable)](http://blog.erratasec.com/2013/09/tor-is-still-dhe-1024-nsa-crackable.html)
