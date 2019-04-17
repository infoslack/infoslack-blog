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

WIP
