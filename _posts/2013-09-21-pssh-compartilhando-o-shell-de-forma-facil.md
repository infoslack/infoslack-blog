---
layout: post
title: "Pssh - Compartilhando o shell de forma fácil"
category: shell
keywords: linux, shell, unix, ssh
---

Já precisou compartilhar rapidamente o shell com um amigo e ficou preso às configurações de SSH e algum multiplexador de terminal?

E se fosse simples fazer isso enviando apenas uma URL ?

### Pssh

De vez em quando, precisamos compartilhar o shell com alguém de forma rápida, mas esbarramos em tarefas como criar um novo usuário para SSH, liberar porta no Firewall e até configurar algum multiplexador de terminal, como `Screen` ou `tmux`, e o que deveria ser rápido acaba consumindo um pouco de tempo.

Pensando nesses problemas, o desenvolvedor [Kelly Martin](https://twitter.com/kellymartin) criou o projeto Open Source escrito em `Ruby` e `JavaScript` chamado [Pssh](https://github.com/portly/pssh) para tornar tudo mais fácil.

O Pssh quando executado, gera uma URL que, quando acessada via browser na porta `8022`, permite ou não, a interação com o shell:

![Compartilhando shell com Pssh](/images/pssh-ex01.png)

Para instalar o Pssh você só vai precisar do Ruby versão 1.9.X ou mais recente:

{% highlight bash %}
$ gem install pssh
{% endhighlight %}

Opções de uso podem ser vistas com o parâmetro -h:

{% highlight bash %}
$ pssh -h
{% endhighlight %}

A opção `--readonly` libera uma sessão para somente leitura, não existe interação com o shell:

{% highlight bash %}
$ pssh --readonly
{% endhighlight %}

O parâmetro `-p` possibilita modificarmos a porta default que é `8022`:

{% highlight bash %}
$ pssh -p 5000
{% endhighlight %}

Se você faz uso de algum multiplexador como tmux ou screen, o Pssh pode ser combinado com eles:

![Tmux e Pssh](/images/tmux-pssh.png)

Contribua com o projeto: [Pssh Github](https://github.com/portly/pssh)

Veja um exemplo prático de uso pelo autor: [Pssh by Portly](http://portly.github.io/pssh/)
