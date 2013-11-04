---
layout: post
title: "Compilando o Kernel Linux"
category: linux
keywords: linux, kernel, compilação, make, modules
---

### Motivação

Você deve estar se perguntando, por que raios vou querer compilar ou
recompilar o kernel ?

Bem um dos principais motivos é a otimização, para moldar o kernel de acordo
com o seu hardware, outro bom motivo seria aplicar patches ao kernel para
eliminar bugs. O kernel Linux por default suporta uma infinidade de
dispositivos além de muitos, muitos recursos.

Um bom exemplo disso é o suporte a rádio amador que vem ativo por padrão:

![Suporte a rádio amador ativo no kernel](/images/kernel-menu.png)

Além desse exemplo existe ainda uma infinidade de outros módulos que dependendo
do nosso hardware não é utilizado e mesmo assim é carregado no boot.

### Relembrando os tipos de kernel

Antes de prosseguir vamos relembrar os tipos de kernel e entender um pouco
sobre como funciona cada tipo.

`Monolítico` é o kernel que une todos os módulos e subsistemas em um único
arquivo executável. Os módulos apesar de não estarem embutidos no código
do kernel, são executados no espaço de memória usado pelo kernel ou
(kernel space), dessa forma o funcionamento continua sendo centralizado.
Essa característica faz com que esse tipo de kernel seja mais rápido que outros.
O Linux, BSD e FreeBSD são exemplos de kernel monolítico.

`Microkernel` é um kernel modular, grande parte dos subsistemas ficam no
(user space) e se comunicam com o núcleo por meio de mensagens. Esse tipo
de kernel é bastante flexível, Minix e OpenSolaris são exemplos desse
tipo de kernel.

`Híbrido` é uma mistura de kernel monolítico com microkernel, ele mantém
alguns subsistemas em seu núcleo e se comunica com os módulos por troca de
mensagens. Por conta disso, possui desempenho menor. Mac OS e Windows são
exemplos de kernel híbrido.

Agora que você já relembrou os tipos de kernel e como os módulos são tratados,
podemos continuar!

### A compilação

O primeiro passo para o processo de compilação é o download do código-fonte:
[kernel.org](https://www.kernel.org/) vale lembrar que é sempre bom baixar
a versão estável.

Feito o download, descompacte o kernel no diretório `/usr/src` e refaça o
link simbólico existente chamado linux para que ele aponte para o diretório
do seu novo kernel.
Entre no diretório do novo kernel que será compilado e acione a interface
de configuração.

Veja o exemplo:

{% highlight bash %}
$ cd /usr/src
$ ls
linux@  linux-3.10.17/  linux-3.8.4/
$ ls -l linux
lrwxrwxrwx 1 root root 13 Oct 27 15:09 linux -> linux-3.10.17/
$ cd linux
$ make menuconfig
{% endhighlight %}

![make menuconfig](/images/menuconfig.png)

A configuração é a parte mais complexa, aqui você escolhe os módulos que
serão acoplados ao kernel, quais serão ativos e quais não estarão disponíveis.

Para compilar um kernel do (zero) é preciso obter todas as informações sobre
o hardware, com os comandos `lspci`, `lscpu`, `lsusb` e `dmidecode` é possível
obter todas as informações necessárias sobre o hardware para esse processo.

No menu de configuração temos opções para a escolha dos módulos, `[ * ]` indica
que o módulo está habilitado para ser incorporado ao kernel na compilação,
`[  ]` desabilitado e `[ M ]` ficará habilitado mas não incorporado ao kernel.

Aqui vamos focar na seguinte situação, você possui uma máquina com uma
distribuição linux instalada e deseja compilar uma versão de kernel mais
atual e de quebra, escolher alguns módulos próprios pro seu hardware.

Como já temos uma distro instalada e funcionando com o nosso hardware atual,
podemos pegar a atual configuração e utilizar como ponto de partida para a
nova compilação. Para isso utilizamos um arquivo de configuração que existe
no diretório `/boot` esse arquivo contém informações sobre os módulos do kernel
que serão carregados durante a inicialização e quais serão ativos por padrão.

O que deve ser feito é copiar o arquivo de configuração para o diretório do
novo kernel que será compilado para servir de base no processo de escolha de
módulos.

{% highlight bash %}
$ cp /boot/config /usr/src/linux/.config
{% endhighlight %}

Após a cópia podemos executar a configuração com `make menuconfig`,
de forma automática ele utilizará o arquivo `.config` que copiamos de `/boot`.
Feito isso, após o menu de configurações ser exibido podemos por exemplo escolher
o nosso modelo de processador e ainda descartar o suporte a outros modelos
fazendo com que o kernel utilize um módulo específico para o hardware em
vez de um módulo genérico.

`Processor type and features` ---> `Processor family`

![Processor family](/images/processor.png)

A opção marcada no exemplo é referente a um modelo de processador Intel,
dessa forma o kernel utilizará o módulo específico em vez do genérico.
Sendo assim no caso do exemplo, poderia ser deabilitado todos os módulos
correspondentes aos processadores AMD.

Finalizada a configuração basta salvar e partir para a próxima etapa.

{% highlight bash %}
$ sudo make bzImage
{% endhighlight %}

Essa é a parte demorada pois depende das escolhas que foram feitas no menu
de módulos e também do hardware. Após concluída com sucesso o novo kernel
estará disponível em `/usr/src/linux/arch/x86/boot`, caso seja 64 bits o
diretório será `/usr/src/linux/arch/ia64/boot`.
O novo kernel compilado ficará disponível com o nome de `bzImage`.

Após o fim da compilação do novo kernel é preciso ainda compilar e instalar os
módulos:

{% highlight bash %}
$ sudo make modules
$ sudo make modules_install
{% endhighlight %}

Depois de instalar os módulos é necessário copiar os novos arquivos gerados
no processo de compilação para o boot, são eles: `.config`, `System.map` e
o kernel propriamente dito `bzImage`.

O `System.map` é uma tabela de símbolos do núcleo do sistema que serve de
consulta para verificar os endereços de cada símbolo na memória. Esse arquivo
é recriado a cada nova compilação.

Copie os arquivos para o `/boot`:

{% highlight bash %}
$ cp /usr/src/linux/.config /boot/config
$ cp /usr/src/linux/System.map /boot/System.map
$ cp /usr/src/linux/arch/x86/boot/bzImage /boot/vmlinuz
{% endhighlight %}

E para finalizar, é preciso ajustar o gerenciador de boot (grub ou lilo)
para que ele carregue o novo kernel que foi compilado.

### Dicas finais

Tudo o que foi mostrado deve funcionar sem problemas em qualquer distribuição
Linux. Você pode optar por automatizar esse processo de compilação criando um
script, no meu caso que uso Slackware mantenho um script como esse:

{% highlight powershell %}
#!/bin/bash

VERSION="3.11.7"
CWD="/usr/src"
cd $CWD

rm -f /usr/src/linux
ln -s /usr/src/linux-$VERSION /usr/src/linux
cd $CWD/linux-$VERSION

cp /boot/config ./.config
make oldconfig && make bzImage && make modules && make modules_install

cd /boot
rm -f vmlinuz System.map config
cp $CWD/linux-$VERSION/.config config-$VERSION
cp $CWD/linux-$VERSION/System.map /boot/System.map-$VERSION
cp $CWD/linux-$VERSION/arch/x86/boot/bzImage /boot/vmlinuz-$VERSION
ln -s vmlinuz-$VERSION vmlinuz
ln -s System.map-$VERSION System.map
ln -s config-$VERSION config

lilo
{% endhighlight %}

Pode ser adaptado para uso em outras distribuições sem complicações.

#### Referências

[Linux Kernel Development (3rd Edition)](http://www.amazon.com/Linux-Kernel-Development-3rd-Edition/dp/0672329468)

[Linux Kernel in a Nutshell](http://www.kroah.com/lkn/)
