---
layout: post
title: "Unikernels, Docker  e o futuro da infraestrutura imutável"
description: "O futuro da infraestrutura imutável com Unikernels ou o que vem depois do Docker"
category: devops
keywords: linux, kernel, devops, docker, unikernel, cloud, infraestrutura, rumpkernel
---

> Sistemas operacionais tradicionais (Linux, FreeBSD, Windows) serão
extintos em servidores. Eles serão substituídos por [hypervisors](https://en.wikipedia.org/wiki/Hypervisor) do
tipo *bare metal* otimizados de forma específica para o hardware.

### O que são Unikernels ?

Quando você executa uma aplicação Ruby, ela faz uso do interpretador que
faz chamadas no sistema operacional, essas chamadas exigem privilégios
que forçam mudanças de contexto (**user space**, **kernel space**) na
aplicação, tudo isso ocorre em um sistema operacional como Ubuntu por exemplo
e que provavelmente é virtualizado com (*VMware*, *Xen*, *KVM*, etc) que roda
em seu próprio sistema operacional de virtualização como *Xen Hypervisor*,
que por sua vez foi instalado em um hardware e este é inicializado por uma BIOS.
No final temos uma sequência de camadas entre o hardware e a aplicação.

O conceito de *Unikernels* em poucas palavras é: remover a gordura que separa
o hardware da aplicação final e manter no sistema operacional apenas o
suficiente para executar o código da aplicação.

Funciona da seguinte forma, o código da aplicação é compilado em um sistema
operacional personalizado que inclui apenas o necessário exigido pela
aplicação, tornando tudo muito pequeno, rápido, eficiente e imutável.

A implementação de [servidores imutáveis](http://martinfowler.com/bliki/ImmutableServer.html) exige que não ocorra atualizações
de aplicativos, alterações de configuração ou updates de segurança. Se
qualquer uma dessas modificações ocorrerem, uma nova imagem deve ser
construída e aplicada para substituir a anterior. Com Docker já é possível
aplicar o conceito de imutabilidade, porém o tamanho final das imagens não
torna viável, tentar fazer o mesmo em máquinas virtuais resulta em imagens
grandes e é neste ponto que unikernels se revela promissor.

Em vez de termos um sistema operacional de "uso geral" nos servidores, podemos
descartar tudo o que não é necessário para o funcionamento da aplicação,
módulos de vídeo e USB por exemplo, não fazem sentido em um ambiente
virtualizado de cloud e podem ser descartados. No final teremos um kernel
especializado e um sistema operacional enxuto tornando fácil aplicar o
conceito de imutabilidade.

Comparando com conteiners e virtualização, pode ser possível reduzir o
tamanho do kernel em até *95%* descartando o que for desnecessário para o
funcionamento da aplicação:

![O caminho até Unikernels](/images/road_to_unikernels.png)

### O ecossistema

Unikernels são escritos em linguagens de alto nível, as mais utilizadas
são: *Rust, Go, OCaml, Haskell* e *Erlang*.
Se você está pensando em escrever o seu próprio unikernel, precisa
conhecer algumas das opções de bibliotecas que fornecem as ferramentas
para isso:

- [MirageOS](https://mirage.io/) escrito em OCaml, cunhou o termo "Unikernel"
- [Rump Kernels](http://rumpkernel.org/) escrito em C, suporta Xen e KVM
- [ClickOS](http://cnp.neclab.eu/clickos/) minimalista(6MB), escrito em C++
- [IncludeOS](http://www.includeos.org/) lembra o anterior, também escrito em C++
- [HaLVM](http://galois.com/project/halvm/) suporta Xen, escrito em Haskell
- [LING](http://erlangonxen.org/) baseado em Erlang com suporte a Xen
- [OSv](http://osv.io/) suporta C, JVM, Ruby e Node

E não acaba ai, você pode ver a lista completa em: [http://unikernel.org/projects/](http://unikernel.org/projects/)

Compreendendo o conceito de unikernels já da para pensar em uso prático,
neste ponto nos deparamos com as particularidades de cada uma das opções
da lista anterior e é ai que entra o Docker.

[No anúncio recente do Docker](http://blog.docker.com/2016/01/unikernel/) revela que [Unikernel Systems](http://unikernel.com/) (uma
empresa formada por desenvolvedores do *MirageOS* e *Rumprun*) agora
faz parte do seu time, então podemos esperar novidades em ferramentas para
gestão de unikernels e containers.

Em uma apresentação na [DockerCon EU](http://unikernel.org/blog/2015/unikernels-meet-docker/), o líder do projeto *MirageOS* [Anil Madhavapeddy](https://twitter.com/avsm), mostrou como o Docker pode ser
usado para construção e gestão de Unikernels.
Na demonstração, uma aplicação PHP com banco de dados foi construída
usando *Rump Kernels* e o *Docker* fez a gestão dos unikernels como containers.

### Um pouco de prática

Aqui temos um exemplo simples com base na apresentação feita na DockerCon,
mas em vez de uma aplicação inteira, vamos criar um unikernel para o Nginx
e entender como ocorre todo o processo de criação.

Vamos utilizar uma máquina Linux com Docker e KVM instalados. Para o processo
de compilação, precisamos do pacote `genisoimage` para gerar os sistemas de
arquivos que serão utilizados no unikernel.

No Ubuntu a instalação pode ser feita da seguinte forma:

{% highlight bash %}
$ sudo apt-get install -y \
    qemu-kvm \
    libvirt-bin \
    ubuntu-vm-builder \
    bridge-utils \
    genisoimage
{% endhighlight %}

Para prosseguir você pode clonar o projeto de demonstração:

{% highlight bash %}
$ git clone git@github.com:infoslack/unikernel-demo.git
{% endhighlight %}

Em seguida podemos pegar uma imagem Docker que contém alguns *Rump Kernels*
pré-construídos, incluindo o do Nginx.

{% highlight bash %}
$ docker pull mato/rumprun-packages-hw-x86_64
{% endhighlight %}

A primeira coisa a ser feita é criar um container que será responsável por
compilar o unikernel para o Nginx:

{% highlight bash %}
$ docker run -ti -d --name=nginx-build mato/rumprun-packages-hw-x86_64:dceu2015-demo cat
{% endhighlight %}

Se estiver curioso, este é o [Dockerfile](https://github.com/mato/rumprun-docker-builds/blob/dceu2015-demo/packages-hw-x86_64/Dockerfile) utilizado para gerar a imagem
que acabamos de usar.

Prosseguindo, agora vamos copiar um módulo chamado `rumprun-setdns`,
escrito em C (padrão usado pelo *Rump Kernels*) que será compilado junto
ao unikernel. Basicamente ele funciona configurando o dns de forma
dinâmica quando o unikernel for inicializado.

Este módulo não é obrigatório e vamos usar apenas para entender como é
possível extender o unikernel com módulos escritos na linguagem usada na
biblioteca padrão, neste caso o Rump Kernels.

{% gist infoslack/aad3587043fe33d539eb %}

Copie o módulo para dentro do container de build e compile:

{% highlight bash %}
$ docker cp rumprun-setdns.c nginx-build:/build/rumprun-setdns.c
$ docker exec nginx-build x86_64-rumprun-netbsd-gcc \
    -O2 \
    -Wall \
    -o rumprun-setdns rumprun-setdns.c
{% endhighlight %}

Agora podemos gerar o binário do nosso unikernel, incluindo o módulo que
foi compilado:

{% highlight bash %}
$ docker exec nginx-build rumprun-bake \
    hw_virtio /build/nginx.bin \
    /build/rumprun-setdns \
    /build/rumprun-packages/nginx/bin/nginx
{% endhighlight %}

O resultado final é um binário chamado `nginx.bin` de aproximadamente 5MB,
usaremos esse binário para inicializar o unikernel, então precisamos copiar
do container de build para nossa máquina, por fim podemos destruir o container
de build:

{% highlight bash %}
$ docker cp nginx-build:/build/nginx.bin .
$ docker rm -f nginx-build
{% endhighlight %}

Na última etapa de configuração é necessário compactar o binário
`nginx.bin`, gerar as imagens *ISO* dos sistemas de arquivos que contém a
estrutura necessária para o funcionamento do Nginx e criar a imagem que
será usada pelo Docker na construção do container do nosso unikernel:

{% highlight bash %}
$ cat nginx.bin | bzip2 > nginx.bin.bz2
$ genisoimage -l -r -o fs/etc.iso fs/etc
$ genisoimage -l -r -o fs/data.iso fs/data
$ docker build -t unikernel/nginx .
{% endhighlight %}

Antes de inicializar o unikernel, vamos criar um container com uma
aplicação simples de resolução de *DNS* entre nossa máquina host e o
container:

{% highlight bash %}
$ docker run -d --hostname resolvable \
    -v /var/run/docker.sock:/tmp/docker.sock \
    -v /etc/resolv.conf:/tmp/resolv.conf mgood/resolvable
{% endhighlight %}

Lembra do módulo `rumprun-setdns` que compilamos ? Ele vai receber
informações passadas por esse container e ajustar as configurações de
DNS do nosso unikernel.

Finalmente podemos inicializar o unikernel por meio do utilitário
`docker-unikernel`, presente no repositório de demonstração:

{% highlight bash %}
$ ./docker-unikernel run -P --hostname nginx unikernel/nginx
INFO: Container id: fbbe0371bc3c
INFO: Created netns fbbe0371bc3c for 31766
INFO: IP address: 172.17.0.3/16 Gateway: 172.17.0.1
INFO: TAP device: /sys/devices/virtual/net/vtap110003/tap2/dev (240:1)
INFO: Devices cgroup: /sys/fs/cgroup/devices/docker/fbbe0371bc3c
{% endhighlight %}

Para testar, podemos simplesmente acessar no browser o caminho `http://nginx`
ou fazer uma requisição via `curl`:

{% highlight bash %}
$ curl -I nginx
    HTTP/1.1 200 OK
    Server: nginx/1.8.0
    Date: Sun, 24 Jan 2016 18:24:05 GMT
    Content-Type: text/html
    Content-Length: 588
    Last-Modified: Sat, 23 Jan 2016 22:04:49 GMT
    Connection: keep-alive
    ETag: "56a3f901-24c"
    Accept-Ranges: bytes
{% endhighlight %}

Podemos verificar o processo do KVM em execução com a instrução:
`ps -ef | grep qemu`.

O que acontece por baixo dos panos é que o Docker inicializa uma *VM*
com base no *Rump Kernels* usando o *KVM* e removendo o que for
desnecessário, como por exemplo o suporte gráfico:

{% highlight bash %}
$ qemu-system-x86_64 \
    -enable-kvm \
    -cpu host,migratable=no,+invtsc \
    -vga none -nographic \
    -kernel ./nginx.bin \
    -net nic,model=virtio,macaddr=${MAC} \
    -net tap,fd=3 \
    -drive if=virtio,file=etc.iso,format=raw \
    -drive if=virtio,file=data.iso,format=raw
...
{% endhighlight %}

Entre as configurações, note o uso do binário que geramos `nginx.bin` como
kernel e a declaração de filesystem para as estruturas necessárias ao
funcionamento do Nginx (`etc.iso` e `data.iso`). Verifique a configuração
completa em `nginx/run.sh`.

O exemplo detalhado aqui foi apenas para fins didáticos, você pode reproduzir
de maneira rápida em poucos passos:

{% highlight bash %}
$ git clone git@github.com:infoslack/unikernel-demo.git
$ cd unikernel-demo
$ make pull
$ make
$ make rundns
$ ./docker-unikernel run -P --hostname nginx unikernel/nginx
{% endhighlight %}

### Conclusão

Acredito que nos próximos 2 anos veremos uma mudança significativa na forma
de prover infraestrutura imutável. Já é possível fazer testes com MirageOS
na Amazon criando instâncias EC2 com unikernel customizado, o mesmo vale
para o [Rumprun utilizado no post](https://www.freelists.org/post/rumpkernel-users/Amazon-EC2-support-now-in-Rumprun).

Por enquanto vou prosseguir os estudos sobre Unikernels e acompanhar as
próximas novidades que irão nascer da parceria com o Docker.

Happy Hacking ;)

### Referências

- [http://unikernel.com/](http://unikernel.com/)

- [http://unikernel.org/projects/](http://unikernel.org/projects/)

- [http://rumpkernel.org/](http://rumpkernel.org/)

- [http://unikernel.org/blog/2015/unikernels-meet-docker/](http://unikernel.org/blog/2015/unikernels-meet-docker/)

- [http://blog.docker.com/2016/01/unikernel/](http://blog.docker.com/2016/01/unikernel/)

- [https://hub.docker.com/r/mgood/resolvable/](https://hub.docker.com/r/mgood/resolvable/)

- [https://github.com/mato/rumprun-docker-builds](https://github.com/mato/rumprun-docker-builds)

- [https://ma.ttias.be/what-is-a-unikernel/](https://ma.ttias.be/what-is-a-unikernel/)

- [http://martinfowler.com/bliki/ImmutableServer.html](http://martinfowler.com/bliki/ImmutableServer.html)

- [After Docker: Unikernels and Immutable Infrastructure](https://medium.com/@darrenrush/after-docker-unikernels-and-immutable-infrastructure-93d5a91c849e#.61tuuxwvt)

- [https://github.com/rumpkernel/rumprun-packages](https://github.com/rumpkernel/rumprun-packages)

- [https://github.com/Unikernel-Systems/DockerConEU2015-demo](https://github.com/Unikernel-Systems/DockerConEU2015-demo)

- [https://github.com/infoslack/unikernel-demo](https://github.com/infoslack/unikernel-demo)
