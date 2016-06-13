---
layout: post
title: "Scanning de portas com Nmap"
description: "Apresentando o Nmap uma ferramenta para scanning de portas e identificação de serviços."
category: security
keywords: security, hacking, pentest, exploit, segurança, invasão, web, nmap, scanning
---

Continuando a saga sobre testes de invasão, neste post veremos detalhes
sobre scanning de portas com o objetivo de coletar mais informações para
a etapa de análise de vulnerabilidades. Porém o foco agora é na
identificação dos softwares que estão sendo utilizados como serviços.

Em um teste de invasão, o escopo é praticamente ilimitado. O alvo pode
estar usando uma quantidade grande de aplicações com problemas de
segurança, os softwares em questão podem ter sido configurados de forma
incorreta na infraestrutura, ou podem ainda estar desatualizados.

O uso do melhor exploit para a vulnerabilidade mais recente não é útil se
o alvo não estiver usando o software vulnerável. Para evitar esse
desperdício, devemos descobrir quais serviços estão ativos e mapear os
softwares que podemos estabelecer comunicação no servidor alvo.

### Scanning manual de portas

Podemos consultar os sistemas em busca de portas que estejam ouvindo, isso
pode ser feito de forma manual ao nos conectarmos às portas com o uso de
ferramentas como o [Netcat](http://netcat.sourceforge.net/):

```bash
$ nc -vv 123.456.789.1 22
li31-114.members.linode.com [123.456.789.1] 22 (ssh) open
SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu7

Protocol mismatch.
 sent 1, rcvd 58
```

Note que com este simples teste verificamos que o serviço de `SSH` está
ativo na porta `22` e depois de estabelecida a conexão, o serviço
retornou se anunciando como `SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu7`.

Banners como este podem ser alterados por administradores para que
contenham qualquer tipo de informação, é um meio de enganar invasores.
Mas na maioria dos casos, as versões exibidas serão bastante precisas e
somente esse tipo de informação vai proporcionar um ponto de partida
durante as pesquisas por vulnerabilidades.

Imagine conectar-se em todas as portas `TCP` e `UDP` possíveis no alvo
para analisar os resultados, isso levaria muito tempo. Para nossa alegria
podemos usar ferramentas específicas para scanning de portas como é o caso
do [Nmap](https://nmap.org/).

### O Nmap

Quando se trata de scanning de portas o Nmap acaba sendo um padrão no
mercado, possui uma vasta documentação e até um [livro](https://nmap.org/book/). Além da
capacidade de determinar não apenas as máquinas ativas, a ferramenta
consegue informações sobre o sistema operacional, as portas em uso,
identificar serviços e possivelmente as respectivas versões.

Aproveitando o exemplo anterior onde verificamos a porta do serviço de
`SSH` de forma manual, no Nmap a porta pode ser especificada com o
parâmetro `-p` o comando ficaria assim:

```bash
$ nmap -p 22 123.456.789.1

Nmap scan report for (123.456.789.1)
Host is up (0.10s latency).
PORT   STATE SERVICE
22/tcp open  ssh
```

Atualmente firewalls com sistemas de prevenção e [IDS(Intrusion detection system)](https://pt.wikipedia.org/wiki/Sistema_de_detec%C3%A7%C3%A3o_de_intrusos),
são bem avançados na detecção e bloqueio de tráfego gerado por scanners,
então pode ser que ao executar um scan com Nmap, nada seja obtido como
resultado. Porém veremos algumas formas de burlar isso evitando a
detecção por parte dos mecanismos de defesa.

### As opções de scanning

Para especificar o tipo de scan que queremos utilizar, o prefixo `-s`
deve ser informado à ferramenta. O parâmetro `-s` minúsculo é seguido de
uma letra maiúscula que determina o tipo de scan. Veremos agora as opções
mais utilizadas:

**Scan stealth** `-sS`, esta é a opção padrão usada pelo Nmap quando
nenhuma opção for definida. Esta opção inicia uma conexão `TCP` com o
alvo, mas não chega a concluir o handshake de três vias:

```bash
$ nmap -sS 123.456.789.1

Starting Nmap 6.47 ( http://nmap.org ) at 2015-06-17 13:20 BRT
Nmap scan report for li15-134.members.linode.com (123.456.789.1)
Host is up (0.11s latency).
Not shown: 990 closed ports
PORT     STATE    SERVICE
21/tcp   open     ftp
25/tcp   filtered smtp
80/tcp   open     http
554/tcp  open     rtsp
646/tcp  filtered ldp
3306/tcp open     mysql
7070/tcp open     realserver
8009/tcp open     ajp13
8010/tcp open     xmpp
9080/tcp open     glrpc

Nmap done: 1 IP address (1 host up) scanned in 4.94 seconds
```

O Nmap inicia o handshake ao enviar um pacote `SYN` para o alvo e tem
como resposta um pacote `SYN-ACK` que não será confirmado, com isso a
conexão ficará aberta pois o canal de comunicação não será estabelecido
por completo. Por padrão, a maioria dos sistemas fecha essa conexão
automaticamente depois de um tempo. Esta opção geralmente é mais difícil
de ser detectada em casos onde o alvo está configurado de forma incorreta.

**Scan TCP connect** `-sT`, geralmente esta opção é utilizada para coletar
mais informações sobre o alvo do que o `stealth`, pois é capaz de
estabelecer uma conexão `TCP` completa. Neste caso as atividades desta
opção serão registradas em log na maioria dos sistemas.

**Scan UDP** `-sU`, com esta opção o scan faz uma avaliação das portas
`UDP` no alvo, esperando receber respostas dos sistemas cujas portas que
forem testadas estejam fechadas.

**Scan ACK** `-sA`, faz a verificação para determinar se uma porta TCP
está filtrada por um firewall ou não. Basicamente esse scan estabelece
uma comunicação com o alvo passando a flag de confirmação `ACK` ligada,
com isso, às vezes, esse tipo de scan consegue passar por firewalls
fingindo ser uma resposta `ACK` a uma solicitação interna do alvo.
Como resposta ele lista as portas que não estão sendo filtradas por um
firewall:

```bash
$ nmap -sA 123.456.789.1

Starting Nmap 6.47 ( http://nmap.org ) at 2015-06-17 13:56 BRT
Nmap scan report for li15-134.members.linode.com (123.456.789.1)
Host is up (0.040s latency).
Not shown: 998 filtered ports
PORT     STATE      SERVICE
554/tcp  unfiltered rtsp
7070/tcp unfiltered realserver

Nmap done: 1 IP address (1 host up) scanned in 14.18 seconds
```

Até agora as opções que vimos não nos dão muitos detalhes sobre os
softwares que estão em uso nas portas, com a opção `-sV` teremos um **Scan
de versões** onde o Nmap realizará uma conexão completa com o alvo para
tentar determinar os softwares em uso e, se possível, as versões:

```bash
$ nmap -sV 123.456.789.1

Starting Nmap 6.47 ( http://nmap.org ) at 2015-06-17 14:09 BRT
Nmap scan report for li15-134.members.linode.com (123.456.789.1)
Host is up (0.11s latency).
Not shown: 990 closed ports
PORT     STATE    SERVICE    VERSION
21/tcp   open     ftp        vsftpd 2.0.8 or later
25/tcp   filtered smtp
80/tcp   open     http       nginx
554/tcp  open     tcpwrapped
646/tcp  filtered ldp
3306/tcp open     mysql      MySQL 5.1.73-log
7070/tcp open     tcpwrapped
8009/tcp open     ajp13      Apache Jserv (Protocol v1.3)
8010/tcp open     xmpp?
9080/tcp open     http       Apache Tomcat/Coyote JSP engine 1.1

Service detection performed.
Nmap done: 1 IP address (1 host up) scanned in 175.19 seconds
```

A coleta de informações nesta etapa começa a fazer sentido, já
conseguimos identificar portas abertas de serviços, o nome dos softwares
e o principal, as respectivas versões.

Mas e o sistema operacional? Bem, o Nmap conta com a opção `-O` que pode
tentar coletar informações e identificar o sistema operacional do alvo:

```bash
$ nmap -sV -O 123.456.789.1

Starting Nmap 6.47 ( http://nmap.org ) at 2015-06-17 14:09 BRT
Nmap scan report for li15-134.members.linode.com (123.456.789.1)
Host is up (0.11s latency).
Not shown: 990 closed ports
PORT     STATE    SERVICE    VERSION
21/tcp   open     ftp        vsftpd 2.0.8 or later
25/tcp   filtered smtp
80/tcp   open     http       nginx
554/tcp  open     tcpwrapped
646/tcp  filtered ldp
3306/tcp open     mysql      MySQL 5.1.73-log
7070/tcp open     tcpwrapped
8009/tcp open     ajp13      Apache Jserv (Protocol v1.3)
8010/tcp open     xmpp?
9080/tcp open     http       Apache Tomcat/Coyote JSP engine 1.1

Running: Linux 2.6.X
OS CPE: cpe:/o:linux:linux_kernel:2.6
OS details: Linux 2.6.9 - 2.6.33

Nmap done: 1 IP address (1 host up) scanned in 175.19 seconds
```

Bingo! O Nmap informa que a versão do Kernel Linux está entre `2.6.9` e
`2.6.33`, além disso indica que pode ser vulnerável.

Existe ainda a opção `-A` que faz o mesmo que `-O` porém de forma mais
agressiva e tenta coletar mais informações.

### Templates de tempo

O Nmap conta com uma funcionalidade de controle de tempo que permite ao
usuário determinar a velocidade de um scan, para que seja mais rápido ou
mais lento que o normal. Este controle serve para aumentar as chances de
sucesso durante um scan, reduzindo o risco de ser detectado.

Cada template de tempo faz uso de vários parâmetros diferentes que podem
ser ajustados, porém as configurações mais significativas: `scan_delay`,
`max_scan_delay` e `max_parallelism` correspondem aos intervalos entre
as sondagens (probes) do scan.

O `scan_delay` determina o intervalo de tempo mínimo entre as sondagens
enviadas ao alvo, já `max_scan_delay` determina o tempo máximo permitido
entre as sondagens e para instruir o sistema a enviar um probe por vez
ou vários ao mesmo tempo, usamos `max_parallelism`. A seguir veremos os
templates e suas características.

**Paranoid** `-T0`, usado principalmente em situações em que os riscos
de detecção devem ser mínimos. O intervalor entre cada verificação desse
scan é de cinco minutos, isso significa que que ele pode levar dias para
concluir, dependendo do número de portas.

**Sneaky** `-T1`, um pouco mais rápido que o paranoid, reduz o tempo
necessário para realizar o scan e ao mesmo tempo ainda consegue ser
discreto. O `scan_delay` é reduzido para 15 segundos e pode levar algumas
horas para finalizar.

**Polite** `-T2`, tem o seu `scan_delay` configurado para 400
milissegundos e faz com que seja mais rápido que os outros dois
anteriores. Pode levar alguns minutos para concluir.

**Normal** `-T3`, este é o default do Nmap se nenhum template de tempo
for definido. Diferente dos outros três anteriores, este template não
faz uso de envio serial, em vez disso ele utiliza a técnica de
processamento paralelo e envia várias sondagens ao mesmo tempo. O
`scan_delay` deste template está configurado para zero e o
`max_scan_delay` pode chegar a 1 segundo por isso o tempo total de
varredura pode ser mais curto.

**Aggressive** `-T4`, assim como o *Normal* esse template possui o seu
`scan_delay` igual a zero e o seu `max_scan_delay` inferior a 1 segundo
com um valor de apenas 10 milissegundos. O tempo total é inferior ao
seu antecessor.

**Insane** `-T5`, este é o template que provê a maior velocidade, possui
o seu `max_scan_delay` com um valor igual a 5 milissegundos.

Dependendo das configurações do alvo e do tipo de scan escolhido, o
resultado da varredura pode trazer informações inconsistentes.

Em boa parte dos casos eu gosto de usar a seguinte combinação:
`nmap -sS -sV -O -Pn host` desta forma tento tirar o máximo de proveito
em um curto tempo. A opção `-Pn` não mencionada antes, desativa o envio
de pacotes `ICMP` e isso faz com que o scan ganhe mais alguns pontos de
discrição.

### Finalizando

Explore a ferramenta e não deixe de conferir a documentação, o que foi
visto aqui é só uma breve introdução. Em outros posts tentarei abordar
mais opções de uso como os tipos de output para armazenar os resultados
do scan e ainda o uso do [Nmap Scripting Engine](https://nmap.org/nsedoc/) para coletar informações
detalhadas sobre vulnerabilidades nos sistemas do alvo.

Happy Hacking ;)

### Referências

- [http://netcat.sourceforge.net/](http://netcat.sourceforge.net/)
- [https://nmap.org/](https://nmap.org/)
- [https://nmap.org/book/](https://nmap.org/book/)
- [https://pt.wikipedia.org/wiki/Sistema_de_detec%C3%A7%C3%A3o_de_intrusos](https://pt.wikipedia.org/wiki/Sistema_de_detec%C3%A7%C3%A3o_de_intrusos)
- [https://nmap.org/nsedoc/](https://nmap.org/nsedoc/)
