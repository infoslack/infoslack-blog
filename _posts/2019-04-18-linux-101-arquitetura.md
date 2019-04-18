---
layout: post
title: "Linux 101 - Arquitetura"
description: "Entendendo como o Linux funciona, arquitetura do Kernel"
category: devops
keywords: linux, kernel, arquitetura, devops
---

Neste post veremos um pouco da arquitetura do Kernel Linux. Como vimos no
[post anterior](https://infoslack.com/devops/linux-101-kernel) o papel do
kernel é fornecer uma interface genérica para os programas e controlar o acesso
aos recursos, lembrando que cada programa em execução no sistema é chamado de
processo e cada processo opera como se fosse o único em execução.

### Arquitetura

![Arquitetura do Kernel Linux](/images/linux-arquitetura.png)

Na parte superior temos o user space, é aqui que os aplicativos do usuário são
executados e abaixo do espaço do usuário temos o kernel space.

Entre eles temos também a biblioteca GNU C ou `glibc` que é responsável por
fornecer a interface de chamada do sistema que se conecta com o kernel,
fornecendo o mecanismo para a transição entre o espaço do usuário e o kernel,
essas transições recebem o nome de `context switching`.

Esse mecanismo é importante porque tanto o kernel quanto o aplicativo do usuário
ocupam diferentes espaços de memória protegidos.

Podemos dividir o Kernel em três níveis. No topo a interface de chamada do
sistema, que implementa as funções básicas, como operações de leitura e escrita.

Abaixo da interface de chamada do sistema ou `syscall` está o código do kernel
que independe de arquitetura, ou seja, este código é comum a todas as arquiteturas
de processadores suportadas pelo Linux.

E abaixo temos o código dependente de arquitetura ou Board Support Package (BSP),
que serve como código específico do processador e da plataforma para a arquitetura em uso.

### Características

O kernel Linux implementa vários atributos arquiteturais importantes, em níveis
altos e baixos, o kernel é separado em vários subsistemas distintos.
O Linux também pode ser considerado monolítico (como expliquei em outro post
[que falo sobre os tipos de kernel](https://infoslack.com/linux/compilando-o-kernel-linux)),
por agregar todos os serviços básicos no kernel.

Isso difere de uma arquitetura microkernel onde o kernel fornece apenas os serviços
básicos, como I/O, gerenciamento de memória e processo, e os serviços mais
específicos são conectados à camada de microkernel.

Mas o aspecto mais interessante do Linux, dado seu tamanho e complexidade, é
sua portabilidade. O Linux pode ser compilado para rodar em um grande quantidade
de processadores e plataformas com diferentes tipos de restrições.

### Subsistemas

![Subsistemas do kernel](/images/subsistemas-kernel.png)

#### SCI

Relembrando, `syscalls` são a porta de entrada controlada no kernel, permitindo
que um processo solicite ao kernel que o mesmo execute alguma ação em seu nome.

O SCI funciona como um serviço de multiplexação e desmultiplexação de chamadas de função.
O kernel torna uma gama de serviços acessível aos programas através da API do
sistema, esses serviços incluem, a criação de um novo processo, executar operações
de I/O ou criando um canal para comunicação entre processos.

De modo geral, funciona assim:

- Uma syscall altera o estado do processador do modo usuário para o modo kernel,
de modo que a CPU possa acessar a memória protegida do kernel.
- O conjunto de system calls é fixo e cada chamada de sistema é identificada por
um número único, geralmente esse esquema de numeração não é visível para os programas,
que identificam as `syscalls` pelo nome.
- Cada `syscall` pode ter um conjunto de argumentos especificando as informações
que devem ser transferidas do espaço do usuário para o espaço do kernel e vice-versa.

#### PM

No kernel os processos são chamados de threads e representam uma virtualização
individual do processador. No espaço do usuário, o termo processo é normalmente
usado para representar um programa em execução, embora a implementação do Linux
não separe os dois conceitos (processos e threads).

O kernel fornece uma API por meio do SCI para criar um novo processo usando funções
como `fork()` ou `exec()`, parar um processo com as funções `kill()` ou `exit()` e
realizar a comunicação e sincronização entre eles.

No gerenciamento de processos existe também a necessidade de compartilhar a CPU
entre as threads ativas. O kernel implementa um algoritmo de agendamento que opera
em tempo constante, independentemente do número de threads que disputam a CPU.

#### MM

O subsistema de gerenciamento de memória do Linux é responsável, como o nome
indica, pelo gerenciamento da memória no sistema, isso inclui a implementação
de memória virtual e paginação por demanda (cada página com tamanho de 4KB,
na maioria das arquiteturas), alocação de memória para estruturas internas do
kernel e programas no espaço do usuário e muitas outras coisas.

O esquema de gerenciamento de memória usa buffers de 4KB como base, mas mantém
o controle de quais páginas estão cheias, parcialmente usadas e vazias.
Permitindo que o esquema cresça e diminua dinamicamente com base nas necessidades do sistema.

Há momentos em que a memória disponível pode ser esgotada, por esse motivo, as
páginas podem ser movidas para fora da memória sendo alocadas em disco.
Esse processo é chamado de `swap` porque as páginas são trocadas da memória
para o disco rígido. Este é um assunto complexo e merece um post separado ;)

#### VFS

![Virtual File System](/images/linux-vfs.png)

O sistema de arquivos virtual (VFS) é um aspecto interessante do kernel do
Linux, pois fornece uma abstração de interface comum para sistemas de arquivos.
O VFS fornece uma camada de comutação entre o SCI e os sistemas de arquivos
suportados pelo kernel.

No VFS, existe uma abstração comum de API de funções como abrir, fechar, ler e
gravar arquivos. Em seguida estão as abstrações do sistema de arquivos que definem
como as funções da camada superior são implementadas.
São plugins para o sistema de arquivos fornecido.

Além disso, o Linux fornece o sistema de arquivos `/proc`, que consiste em um
conjunto de diretórios e arquivos montados sob o diretório `/proc`.
Este é um sistema de arquivos virtual que fornece uma interface para estruturas
de dados do kernel que se parece com arquivos e diretórios em um sistema de arquivos comum.

Isso fornece um mecanismo fácil para visualizar e alterar vários atributos do
sistema exibindo um conjunto de diretórios com nomes no formato `/proc/PID`,
onde o `PID` é o `ID` de um processo. Com isso é possível visualizar informações
sobre cada processo em execução no sistema.
Geralmente o conteúdo de `/proc` está em formato de texto legível e um programa
pode simplesmente abrir, ler ou gravar no arquivo desejado.

Abaixo da camada do sistema de arquivos temos o cache de buffer, que fornece
um conjunto de funções para a camada do sistema de arquivos.
Essa camada de armazenamento em cache otimiza o acesso aos dispositivos físicos
mantendo os dados por um curto período de tempo.

Logo abaixo do cache de buffer estão os drivers de dispositivo, que implementam
a interface para o dispositivo físico específico.

#### Network Stack

A pilha de rede, por padrão, segue uma arquitetura em camadas modelada após os
próprios protocolos. Lembrando que o Protocolo da Internet (IP) é o protocolo
da camada de rede básica que fica abaixo do protocolo de transporte ou Protocolo
de Controle de Transmissão (TCP).

Acima de TCP temos a camada de sockets, que é chamada por meio do SCI. A camada
de sockets é a API padrão para o subsistema de rede e fornece uma interface de
usuário para uma variedade de protocolos de rede. Desde o acesso as data units
do protocolo IP (PDUs) e até o TCP e o UDP, a camada de sockets fornece uma
maneira padronizada de gerenciar conexões e mover dados entre endpoints.

#### DD

A maior parte do código fonte do Kernel Linux é composta de drivers de
dispositivos que tornam um determinado dispositivo de hardware utilizável.

A estrutura de diretórios nos fontes do Linux fornece um subdiretório de drivers
que é dividido pelos vários dispositivos suportados, como Bluetooth, USB,
serial e assim por diante.

#### ARCH

Embora a maior parte do Linux seja independente da arquitetura na qual ele é
executado, existem elementos que precisam considerar a arquitetura em uso para
operações eficiêntes. O subdiretório `/arch` define a parte dependente da
arquitetura contida em vários subdiretórios específicos formando o `BSP`.

Geralmente o diretório `x86` é usado. Cada subdiretório de arquitetura contém
vários outros subdiretórios que se concentram em um aspecto específico do kernel,
como inicialização, gerenciamento de memória, virtualização e outros.

### Conclusão

Até agora vimos vários conceitos fundamentais e limitados relacionados ao
funcionamento do Kernel Linux. Nos próximos posts tentarei aprofundar um pouco
mais em cada parte que vimos até agora.

### Referências

- [https://nostarch.com/tlpi](https://nostarch.com/tlpi)
- [https://www.kernel.org/doc/html/latest/admin-guide/mm/index.html](https://www.kernel.org/doc/html/latest/admin-guide/mm/index.html)
