---
layout: post
title: "Como vai a segurança de suas aplicações Ruby on Rails ?"
description: "Conheça algumas ferramentas para testar a segurança de suas aplicações rails"
category: security
keywords: hacking,hacker,security,segurança,teste,invasão,ruby,rails,metasploit,hakiri
---

Durante o processo de desenvolvimento de uma aplicação temos 1001 coisas
para nos preocupar, o design de uma API, detalhes do banco de dados,
dependências que serão adicionadas ao projeto, estratégias para deploy,
infra, etc. A segurança da aplicação acaba sendo apenas mais um detalhe
que será esquecido, bugs violentos serão adicionados ao projeto, seja
por meio de uma gem que foi inserida, ou por falta de testes ou no pior
dos casos, por falta de atualizações.

Apresento algumas soluções que podem ajudar em 2 casos:

### 1 - Durante o processo de desenvolvimento

É possível verificar a existência de bugs na etapa de desenvolvimento,
algumas ferramentas fazem uma análise estática de código, o [Akita fez um
post sobre isso](http://www.akitaonrails.com/2014/05/22/seguranca-em-rails). Da lista particularmente eu gosto de duas que fazem uso da
base de vulnerabilidades [Ruby Advisory DB](https://github.com/rubysec/ruby-advisory-db/), [Hakiri Facets](https://hakiri.io/facets) e [Hakiri Toobelt](https://github.com/hakirisec/hakiri_toolbelt).

No Facets você faz o upload do seu `Gemfile.lock` e ele vasculha na base de
vulnerabilidades em busca de alguma CVE compatível com a versão de suas gems, o
resultado pode ser uma lista bem grande de bugs caso o projeto esteja bem desatualizado:

![Hakiri Facets result](/images/hakiri.png)

Já no Toobelt é possível testar da mesma forma sem sair da sua zona de conforto,
adicionando a gem hakiri e gerando um arquivo de manifesto:

```bash
$ gem install hakiri
$ hakiri manifest:generate
-----> Generating a manifest file...
       Generated a manifest file in /projects/xpto/manifest.json
       Edit it and run "hakiri system:scan"
```

Depois de editar o arquivo de manifesto e adicionar as informações complementares,
basta executar a verificação:

```bash
$ hakiri system:scan
-----> Scanning system for software versions...
       Found Ruby 2.1.3.242
       Found Ruby on Rails 3.2.11
-----> Searching for vulnerabilities...
       Found 17 vulnerabilities in Ruby on Rails 3.2.11
       Show all of them? (yes or no)

CVE-2013-0276
ActiveRecord in Ruby on Rails before 2.3.17, 3.1.x before 3.1.11, and
3.2.x before 3.2.12 allows remote attackers to bypass the
attr_protected protection mechanism and modify protected model
attributes via a crafted request.
...
```

É uma verificação que não leva tanto tempo para rodar e pode ser implantada
junto ao serviço de CI por exemplo.

### 2 - Para convencer o seu chefe ou time a manter tudo atualizado

Esta é talvez a parte mais complicada de se fazer, pois envolve pessoas.
Tudo fica mais fácil se você mostra na prática os argumentos para que todos
ajudem a manter o projeto atualizado. Neste caso minha proposta é simples,
hackear o projeto e mostrar por A+B que segurança é coisa séria.

Em outro [post](http://infoslack.com/security/conheca-o-metasploit-framework/) escrevi sobre uma das ferramentas que mais gosto para
fazer esse tipo de teste e provar a existência de vulnerabilidades,
o [Metasploit](http://www.metasploit.com/).

Confira um exemplo de uso da ferramenta explorando uma aplicação Rails
e conseguindo acesso total ao servidor:

{% youtube sa6S9a0EhYs %}

Em janeiro de 2015 a [CVE-2013-0156](http://www.cvedetails.com/cve/2013-0156) que corresponde ao bug explorado
na demonstração completa 2 anos e ainda continua bastante ativa na web,
o pior em sites conhecidos e grandes aplicações.

### Finalizando

Agora você não tem mais motivos para adiar as atualizações, lembrando que
o mesmo ocorre com atualizações de segurança nos servidores e em outras
partes do seu projeto.

Se precisar de uma consultoria me chama!

Happy Hacking ;)

### Referências

- [http://www.metasploit.com/](http://www.metasploit.com/)

- [http://www.cvedetails.com/cve/2013-0156](http://www.cvedetails.com/cve/2013-0156)

- [https://hakiri.io/facets](https://hakiri.io/facets)

- [https://github.com/hakirisec/hakiri_toolbelt](https://github.com/hakirisec/hakiri_toolbelt)

- [https://github.com/rubysec/ruby-advisory-db/](https://github.com/rubysec/ruby-advisory-db/)

- [http://www.akitaonrails.com/2014/05/22/seguranca-em-rails](http://www.akitaonrails.com/2014/05/22/seguranca-em-rails)

- [Slides da minha palestra na RubyConf sobre Metasploit](http://infoslack.com/rubyconf/)
