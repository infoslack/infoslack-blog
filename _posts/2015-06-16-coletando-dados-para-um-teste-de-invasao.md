---
layout: post
title: "Coletando dados para um teste de invasão"
description: "Explicação da etapa de coleta de informações para um teste de invasão."
category: security
keywords: security, hacking, pentest, exploit, segurança, invasão, web, netcraft, fierce
---

No post anterior vimos uma breve introdução sobre testes de invasão,
agora veremos com um pouco mais de detalhes a etapa de coleta de dados.

O objetivo desta fase é conseguir o máximo possível de informações
relevantes sobre o alvo. O sysadmin costuma escrever em listas sobre como
garantir a instalação segura do PostgreSQL ? O CEO fala demais no Twitter
sobre as tecnologias utilizadas na aplicação principal da empresa ? O
sucesso de um teste de invasão depende muito do resultado da fase de
coleta de informações.

Os dados coletadas nesta fase serão utilizadas na etapa de verificação
de vulnerabilidades, veremos agora algumas ferramentas para obter
iformações interessantes.

### Coleta de informações públicas

Uma empresa chamada [Netcraft](http://www.netcraft.com/) faz o log do uptime e consultas sobre os
softwares utilizados em empresas de web hosting e servidores web, as
informações são disponibilizadas de forma pública.

Ao fazermos uma consulta à procura de `www.infoslack.com` podemos notar
que o domínio foi registrado em `name.com` e tem um endereço IP
`66.228.54.103` de uma VPS na `Linode`, além disso vemos que o servidor
está executando Linux com um web server `Nginx`:

![coletando dados com netcraft](/images/netcraft-infoslack.png)

De posse dessas informações, durante um teste de invasão já poderiamos
descartar vulnerabilidades relacionadas aos web servers `Apache` e
`Microsoft IIS` por exemplo. Ou ainda poderiamos tentar usar a engenharia
social enviando um e-mail para o administrador fazendo com que pareça ter
sido enviado pela `Name.com`.

Em muitos casos estas mesmas informações podem ser coletadas com os
comandos `whois`, `nslookup` e `host` porém existem casos onde é possível
ocultar os detalhes durante o registro do domínio. Um outro caso
interessante é quando o alvo está fazendo uso de um serviço de CDN como
o [CloudFlare](https://www.cloudflare.com/), por exemplo, toda informação coletada com o `whois`
neste caso será referente ao CDN e não ao alvo em questão. Quando isso
acontece, é comum conseguir ver o histórico de mudanças no `Netcraft` e
obter o endereço IP real do servidor do alvo antes de ter feito a
mudança para o uso do CDN:

![netcraft history](/images/netcraft-02.png)

Existe uma outra alternativa para descobrir informações de um domínio,
um scanner muito leve chamado [Fierce](https://github.com/davidpepper/fierce-domain-scanner), escrito em `Perl` e desenvolvido
por [RSnake](https://twitter.com/rsnake). Basicamente por meio de brute-force e outras técnicas, o
scanner tenta descobrir detalhes do alvo como o IP do host, mesmo que
este seja camuflado com um CDN:

```bash
root@labs:~# perl fierce.pl -dns dominioalvo.com.br

DNS Servers for dominioalvo.com.br:
	gina.ns.cloudflare.com
	doug.ns.cloudflare.com

Trying zone transfer first...
	Testing gina.ns.cloudflare.com
		Request timed out or transfer not allowed.
	Testing doug.ns.cloudflare.com
		Request timed out or transfer not allowed.

Unsuccessful in zone transfer (it was worth a shot)
Okay, trying the good old fashioned way... brute force

Checking for wildcard DNS...
	** Found app.dominioalvo.com.br at 54.321.12.34.
	** High probability of wildcard DNS.

Now performing 2280 test(s)...
	104.28.14.30    www.dominioalvo.com.br
	104.28.15.30    www.dominioalvo.com.br

Done with Fierce scan: http://ha.ckers.org/fierce/
Found 2 entries.

Have a nice day.
```

Perceba que na linha `17` o scanner encontrou uma resposta diferente para
o subdomínio `app` identificando o ip `54.321.12.34` que não tem
relacionamento com o CloudFlare exibido na transferência de zona do
domínio.

### Finalizando

Além das ferramentas abordadas vale conferir outras como [theHarvester](https://github.com/laramies/theHarvester)
usada para coletar emails referentes a um domínio, ou ainda ferramentas
para mineração de dados como é o caso do [Maltego](https://www.paterva.com/web6/products/maltego.php).

Fique atento e não deixe de acompanhar o blog, no próximo post veremos
mais detalhes sobre coleta de informações.

Happy Hacking ;)

### Referências

- [http://www.netcraft.com/](http://www.netcraft.com/)
- [https://www.cloudflare.com/](https://www.cloudflare.com/)
- [https://github.com/davidpepper/fierce-domain-scanner](https://github.com/davidpepper/fierce-domain-scanner)
- [https://github.com/laramies/theHarvester](https://github.com/laramies/theHarvester)
- [Maltego](https://www.paterva.com/web6/products/maltego.php)
