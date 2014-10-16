---
layout: post
title: "Manipulando a memória RAM e a SWAP"
description: "Aprenda a controlar a memória RAM e a fazer um melhor uso da SWAP no Linux"
category: linux
keywords: linux, ram, swap, kernel
---

Alguma vez você já precisou limpar o cache da memória RAM ou SWAP no linux ?

O Linux utiliza o espaço na memória cache para salvar programas e comandos que foram utilizados recentemente, isso permite executá-los mais rapidamente no futuro. É interessante saber manipular esse espaço na memória, vejamos como:

### Limpando o cache da RAM

{% highlight bash %}
$ sync
$ echo 3 > /proc/sys/vm/drop_caches
{% endhighlight %}

Ou podemos usar o `sysctl` para configurar parâmetros de kernel em runtime:

{% highlight bash %}
$ sysctl vm.drop_caches=3
{% endhighlight %}
<br />
* o `sync` faz com que todos os arquivos de cache do sistema sejam descarregados da memória e armazenados em disco, assim não perdemos os dados que estão na RAM
* a opção `3` faz o kernel liberar pagecache, dentries e inodes
* outras opções: `1` faz o kernel liberar somente pagecache, `2` libera inodes e pagecache
* para saber mais: [Drop Caches](http://linux-mm.org/Drop_Caches) e [Sysctl vm](https://www.kernel.org/doc/Documentation/sysctl/vm.txt)
<br />
### Controlando a SWAP

É possível configurar e controlar o comportamento da SWAP através de um parâmetro do kernel no arquivo `/proc/sys/vm/swappiness`. Este arquivo contém um número de 0 a 100, onde o sistema determina a predisposição para fazer uso da SWAP.

Um número baixo faz com que ele use a SWAP apenas em situações extremas, enquanto que um número maior aumenta o uso de SWAP e mantém a memória RAM com mais espaço livre.

Aumentar ou diminuir o uso de SWAP:

{% highlight bash %}
$ echo "90" > /proc/sys/vm/swappiness
$ echo "10" > /proc/sys/vm/swappiness
{% endhighlight %}

ou use o `sysctl` para passar esses parâmetros de kernel em runtime


{% highlight bash %}
$ sysctl vm.swappiness=20
{% endhighlight %}

No final lembre-se de resetar a SWAP para validar as configurações:

{% highlight bash %}
$ swapoff -a
$ swapon -a
{% endhighlight %}
