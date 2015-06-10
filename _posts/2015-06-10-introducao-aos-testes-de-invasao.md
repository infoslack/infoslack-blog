---
layout: post
title: "Introdução aos testes de invasão"
description: "Breve visão das fases de um teste de invasão"
category: security
keywords: security, hacking, pentest, exploit, segurança, invasão, web
---

De tempos em tempos nos deparamos com notícias sobre empresas de grande
porte que foram vítimas de algum tipo de ciberataque. O que chama atenção
é que os invasores não fizeram uso da última e mais recente
vulnerabilidade descoberta, em vez disso estão explorando falhas antigas
de injeção de SQL, aplicando ataques de engenharia social contra os
funcionários ou simplesmente estão fazendo ataques de força bruta para
descobrir senhas fracas. Resumindo, as empresas acabam expondo detalhes
pessoais de seus clientes em consequência de brechas de segurança que
poderiam ter sido evitadas com correções.

A função de um teste de invasão é descobrir esses problemas antes que um
invasor o faça e além disso fornecer recomendações sobre como corrigir os
problemas encontrados e evitar futuras vulnerabilidades. Veremos a seguir
as fases que compõem um teste de invasão.

### Preparação

Nesta fase todo o escopo do teste é definido, quais endereços `IP` ou
`hosts` deverão ser testados, que tipo de teste deverá ser feito, se é
permitido realizar um ataque de engenharia social e ainda é dedicado
um tempo para entender os objetivos de negócio do cliente.

Além disso é comum a exigência de que os testes sejam realizados somente
em uma janela de horários específica ou em dias determinados, todos esses
detalhes são discutidos na etapa de preparação.

### Coleta de dados

Nesta fase toda a coleta de informações disponíveis é aplicada por um
processo chamado de `OSINT` (Open Source Intelligence). É aqui que
começamos a utilizar ferramentas como scanners de portas com o objetivo
de identificar quais sistemas estão em uso, bem como as respectivas
versões.

### Análise de vulnerabilidades

Aqui as vulnerabilidades começam a ser encontradas, neste ponto podemos
determinar até onde uma estratégia de exploração de falha pode ser
bem-sucedida. É nesta fase que utilizamos scanners de vulnerabilidades
que aplicam comparações com as versões dos softwares detectados na coleta
de dados em uma base de vulnerabilidades para obter um bom chute a
respeito de quais bugs podem estar presentes no sistema alvo.

Vale lembrar que embora os scanners de vulnerabilidades sejam ferramentas
fantásticas, elas não substituem o raciocínio crítico de uma verificação
manual.

### Exploração de falhas

A fase mais esperada, neste ponto a execução de exploits é aplicada contra
as vulnerabilidades encontradas, com o uso de ferramentas como por exemplo
o `Metasploit`, ou ainda de forma manual.

### Pós-exploração

Nesta fase é onde determinamos o que a invasão obtida na etapa anterior
significa para o cliente. Durante o processo de pós-exploração de falhas,
informações sobre o sistema invadido são coletadas, por exemplo um dump
da base de dados pode ser feito ou ainda tentar usar a máquina explorada
para atacar outros sistemas que não estavam anteriormente visíveis.

### Relatórios

A última fase de um teste de invasão é a geração dos relatórios, aqui
todas as descobertas são informadas de maneira detalhada. É comum
explicar o que ele está fazendo de forma correta para introduzir os
pontos que devem ser melhorados, em seguida detalhar sobre como você
conseguiu invadir o sistema, o que foi descoberto e o que fazer para
corrigir. Vale lembrar que o relatório deve ser escrito de forma clara
para que todos incluindo o pessoal que não seja da área técnica possam
ler.

### Tipos de testes de invasão

Os testes de invasão podem ser classificados em tipos, conforme a
quantidade de informações apresentadas ao profissional de segurança:

- `Blind` simula todas as condições de um atacante real, onde o mesmo
possui acesso apenas às informações públicas do alvo, o cliente sabe que
será testado e o que será feito durante o teste.

- `Double Blind` possui as mesmas características do `Blind`, porém a
equipe de TI do alvo não é avisada sobre a execução do teste.

- `Gray Box` as informações fornecidas sobre o alvo são parciais de
forma a antecipar a execução do teste.

- `Double Gray Box` possui as mesmas características do `Gray Box`, porém
a equipe de TI do alvo não sabe quais testes serão executados.

- `Tandem` todas as informações sobre o alvo são passadas para o atacante
e o alvo sabe exatamente o que será testado.

- `Reversal` simula um atacante que tem conhecimento total sobre o alvo,
porém o alvo não sabe que será atacado, muito menos que testes serão
realizados.

Particularmente eu gosto de resumir em apenas dois tipos e costumo
chamá-los de `Blackbox`(sem informações relevantes ou qualquer acesso) e
`Whitebox`(com o máximo de informações relevantes).

### Finalizando

Abordarei com detalhes e exemplos práticos em outros posts cada uma das
etapas que foram listadas aqui.

Se você ficou interessado sobre o assunto e quer aprender mais deixe o
seu comentário e confira a grade dos workshops: [Começando com testes de invasão](http://infoslack.com/workshops/pentest/)
e [Web hacking na prática](http://infoslack.com/workshops/web-hacking/).

Happy Hacking ;)

### Referências

- [http://www.pentest-standard.org](http://www.pentest-standard.org/index.php/Main_Page)
- [https://www.owasp.org/](https://www.owasp.org/index.php/Main_Page)
- [http://www.2-sec.com/penetration-testing/](http://www.2-sec.com/penetration-testing/)
