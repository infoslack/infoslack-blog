---
layout: post
title: "Atualize o authorized_keys no servidor usando gist"
category: server
keywords: server, linux, unix, services, servidor, gist, github, ssh, keys
---

Imagine que você está trabalhando com sua equipe no desenvolvimento de um novo
produto e te pediram para configurar um servidor de testes para rodar o projeto.

Acontece que após a instalação e configuração do server você recebe o pedido de
um amigo do time para que adicione a chave pública dele no `authorized_keys`,
não é incômodo, depois de alguns dias outro amigo faz o mesmo pedido e o primeiro
que te pediu teve que reinstalar o sistema e esqueceu de fazer backup das chaves
e agora a tarefa de atualizar o `authorized_keys` começa a virar tortura.

Pensando nesse problema podemos pedir para que o servidor leia um [gist](https://gist.github.com/) com
as informações necessárias para que essa tarefa seja realizada de forma mais
prática.

Para isso vamos precisar criar um gist de preferência **privado** com a lista das
chaves públicas de quem deve ser inserido nas configurações como mostra o exemplo:

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5OnYust5S9hwLb4tAtVMOVlRmszam...
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgRjYuFXqVv1x0WHnNxz3s4doTpx7v...
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsizI0Nt5wMunAYd2t3daTxnHZBMlW...

Feito isso vamos ao servidor configurar o **cron** para que faça a atualização
de forma automática, `$ sudo crontab -e`:

{% highlight powershell %}
0 0 * * * mkdir -pm 700 ~/.ssh > /dev/null 2>&1 ; curl -s -w \%{http_code} \
https://gist.githubusercontent.com/infoslack/867c9e934af23ee8ae6e/raw/\
9cde7b86acdda0a3f4d74ee801e4a7bae57f2a08/keys_white_list --output \
~/.ssh/authorized_keys_dl 2> /dev/null | grep 200 > /dev/null && mv -f \
~/.ssh/authorized_keys_dl ~/.ssh/authorized_keys && chmod 600 \
~/.ssh/authorized_keys > /dev/null 2>&1
{% endhighlight %}

Ok é assustador, mas vamos entender esse comando feio primeiro, estou informando
para o cron que todo dia a meia-noite ele crie o diretório `~/.ssh` com a
permissão 700 e caso o diretório já exista que mantenha a sua estrutura, em seguida
estamos redirecionando as mensagens de erro para `/dev/null` depois disso o **curl**
entra em ação pegando as informações no nosso gist e salvando em um arquivo com
o nome de `authorized_keys_dl` onde mais uma vez as mensagens de erro são ignoradas,
como passamos um argumento para o **curl** adicionar ao final do arquivo o status
http da url, fazemos um grep para verificar se está ok, caso não venha esse código
mas um outro como *404* a atualização será interrompida.
Depois disso movemos o arquivo baixado para o nome correto `authorized_keys` e
alteramos a permissão para 600, sempre enviando o `stderr` para `/dev/null`.

Agora que entendemos o que está sendo feito, vamos melhorar essa instrução.
Podemos elaborar um *shell script* bastante reduzido e claro mais legível, mas
antes vamos dar uma olhada em uma feature legal que o github oferece, que é
exibir as chaves públicas dos usuários, simples assim:
[https://github.com/infoslack.keys](https://github.com/infoslack.keys).

Dessa forma em vez de manter um gist com todas as chaves públicas, podemos ter
uma lista de usuários, nosso script ficaria assim:

{% highlight powershell %}
#!/bin/sh

URL="RAW_URL_PRIVATE_GIST"
TMP="/tmp/authorized_keys_dl"
ERR="/dev/null 2>&1"

mkdir -pm 700 ~/.ssh > $ERR

for user in $(curl --silent $URL)
do
  curl -s "https://github.com/"$user".keys" -w "\n" >> $TMP
done

mv -f $TMP ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys > $ERR
{% endhighlight %}

E o *cron* ficaria assim:

{% highlight powershell %}
0 0 * * * /opt/scripts/update_authorized_keys.sh
{% endhighlight %}

E o gist teria a **whitelist** dos usuários:

    infoslack
    initsec
    daniel_romero
    ...

O tempo do cron poderia ser ajustado para intervalos menores ou você poderia
até mesmo fazer algo legal com o monit.

Happy Hacking ;)
