---
layout: post
title: "Conheça o Metasploit Framework"
description: "Teste a segurança de suas aplicações, conheça o Metasploit Framework!"
category: security
keywords: security, hacking, metasploit, pentest, exploit, segurança, invasão
---

### Introdução

O [Metasploit](http://www.metasploit.com/) é um projeto open source criado
por [HD Moore](https://twitter.com/hdmoore) com o objetivo de fornecer um ambiente adequado para o
desenvolvimento, testes de segurança e exploração de vulnerabilidades de
software.

O projeto nasceu em 2003 com o objetivo de fornecer informações úteis sobre a
realização de testes de invasão e compartilhar algumas ferramentas. O primeiro
release foi lançado oficialmente apenas em 2004 e contava com alguns exploits
escritos em C, Perl e Assembly.

Quando a versão 3.x foi lançada em 2007 o framework foi quase que totalmente
reescrito em [Ruby](https://www.ruby-lang.org/en/), isso facilitou bastante
a criação de novos exploits e atraiu novos desenvolvedores para o projeto.

Em 2009 a [Rapid7](http://www.rapid7.com/) compra o Metasploit e um ano depois
lança a versão comercial do projeto o [Metasploit Pro](http://metasploit.pro).

### Arquitetura e Funcionalidades

![Arquitetura do metasploit](/images/msf-arquitetura.png)

O **REX(Ruby Extension Library)** é o núcleo do Metasploit, ele disponibiliza
a API com funcionalidades que ajudam no desenvolvimento de um exploit, além de
bibliotecas, sockets e protocolos.

O **CORE** do framework é constituído de sub-sistemas que controlam sessões,
módulos, eventos é a API base.

O **BASE** fornece uma API amigável e simplifica a comunicação com outros
módulos, interfaces e plugins.

Na camada **MODULES** é onde reside os exploits e payloads, basicamente
os exploits são programas escritos para explorar alguma falha e o payload
é como um complemento para o exploit. Basicamente o payload é o código que
vai ser injetado no alvo, ao ser injetado alguma ação pré-definida será
executada, por exemplo: (realizar um download, executar um arquivo, apagar
alguma informação ou estabelecer uma conexão com outro sistema).

A camada de **INTERFACES** conta com o modo **console** onde temos um shell poderoso
que trabalha em conjunto com o SO, o **cli** que fornece uma interface onde
é possível automatizar testes de invasão e ainda temos interfaces **web** e **gui**.

### Um exemplo prático de uso

Vamos à prática e ver um pouco do que é possível fazer com o Metasploit.
Para este exemplo usei como alvo uma máquina com Windows 7 (desatualizada)
e explorei uma falha que permite a execução de código remoto no SO.

Metasploit em ação:

![Metasploit msfconsole](/images/msf-console.png)

O exploit usado explora uma vulnerabilidade na manipulação de arquivos do
Windows na criação de um atalho (arquivos .lnk), durante este ataque o metasploit
cria um serviço e espera o alvo acessar a URL para injetar um DLL malicioso no sistema.

No console do metasploit informo o exploit que irei usar com o comando `use`:

```bash
msf > use exploit/windows/browser/ms10_046_shortcut_icon_dllloader
msf exploit(ms10_046_shortcut_icon_dllloader) >
```

Em seguida listo as opções oferecidas para a execução do exploit:

![show options](/images/msf-options.png)

Executando o comando `show payloads` o framework irá listar todos os módulos
de payload suportados pelo exploit escolhido, no teste usei o `meterpreter`.

O Meterpreter é dos payloads mais poderosos do Metasploit, ele tenta ficar
invisível ao sistema alvo durante um ataque, ou seja ele utiliza recursos para
não ser pego por firewalls ou **IDS(Intrusion Detection System)**.

Após escolher o `payload` listamos as opções novamente para ver mais recursos,
dessa vez sobre o payload escolhido:

![show options payload](/images/msf-payload-options.png)

Agora só precisamos setar os parâmetros nas opções de uso do exploit, no caso
apenas 2 são obrigatórias o `LHOST` e o `SRVHOST`.

As opções `SRVHOST` e `LHOST` recebem como argumento o ip do host atacante,
sendo a `SRVHOST` parâmetro para o exploit e `LHOST` parâmetro para o payload.

![msf set options](/images/msf-set-options.png)

Após as configurações feitas, executamos o exploit:

![msf run exploit](/images/msf-run-exploit.png)

O metasploit executa um web server nesse momento e aguarda em background que o
alvo acesse a URL "infectada" para injetar o payload e criar uma conexão reversa
com o atacante.

Enquanto o metasploit fica aguardando, o alvo acessou a URL http://192.168.25.10:

![msf ataque](/images/msf-ataque.png)

O alerta de segurança no alvo solicita permissão para abrir o conteúdo que
está sendo disponibilizado pelo metasploit, no exemplo um usuário sem atenção
clicou em `Permitir`, enquanto isso no console do metasploit o ataque é efetivado
e cada etapa é informada:

![msf exploiting](/images/msf-exploit.png)

Por fim a conexão reversa é estabelecida ou seja o alvo conectou-se ao atacante,
uma sessão do `meterpreter` é aberta e agora podemos entrar no **MS-DOS** do alvo:

```bash
meterpreter >
meterpreter > shell
Process 3180 created.
Channel 1 created.
Microsoft Windows [versão 6.1.7600]
Copyright (c) 2009 Microsoft Corporation. Todos os direitos reservados.

C:\Windows\system32>

C:\>dir
dir
 O volume na unidade C não tem nome.
 O Número de Série do Volume e 5499-BEB2

 Pasta de C:\

10/06/2009  18:42                24 autoexec.bat
10/06/2009  18:42                10 config.sys
13/07/2009  23:37    <DIR>          PerfLogs
23/10/2013  20:07    <DIR>          Program Files
18/11/2012  19:16    <DIR>          Users
17/05/2013  20:21    <DIR>          Windows
               2 arquivo(s)             34 bytes
               4 pasta(s)      996.515.840 bytes disponíveis

C:\>
```

Simplesmente agora temos acesso total a máquina!

### Finalizando

O **Metasploit** é uma ferramenta super poderosa e com muitas opções e recursos
para serem explorados, o framework ainda oferece opções para explorar falhas em:
aplicações web, mobile, firmwares, etc.

Existe uma documentação em forma de tutorial muito completa sobre o metasploit:
[Aqui!](http://www.offensive-security.com/metasploit-unleashed/Main_Page)

Acompanhe o projeto no Github: [rapid7/metasploit](https://github.com/rapid7/metasploit-framework)

Para mais detalhes sobre a falha explorada no exemplo do post:

* [Microsoft Security Advisory 2286198](http://technet.microsoft.com/en-us/security/advisory/2286198)
* [MSB-MS10-046](http://technet.microsoft.com/en-us/security/bulletin/MS10-046)
* [CVE-2010-2568](http://cvedetails.com/cve/2010-2568)

Esse conteúdo será visto no curso:
[Começando com testes de invasão](http://infoslack.com/security/curso-comecando-com-testes-de-invasao/)
com mais detalhes!

=)
