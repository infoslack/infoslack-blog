---
layout: post
title: "Criando uma comunicação segura com OpenVPN"
description: "Faça comunicações seguras utilizando o OpenVPN"
category: security
keywords: security, hacking, vpn, ,openvpn, vps, segurança, invasão, privacidade, túnel, criptografia
---

Imagine que você está viajando e que chegando ao hotel a primeira coisa a fazer
foi conectar-se ao Wi-Fi para ler seus e-mails, verificar alguma coisa no internet
banking ou para terminar alguma tarefa pendente.

O problema é que você nunca sabe quem está conectado na mesma rede, ou o que estão
fazendo na rede. Pode ter alguém capturando os pacotes que trafegam ou pior pode ter
um [sniffer](http://en.wikipedia.org/wiki/Packet_analyzer) monitorando todas as
conexões. Mesmo que os serviços que você utilize façam uso de *https* é possível
ler os pacotes antes de serem criptografados fazendo uso do: [SSLstrip](https://pypi.python.org/pypi/sslstrip).

A imagem abaixo reflete o cenário onde temos alguém espionando a rede, capturando
as informações que estão trafegando:

![Acesso inseguro](/images/vpn-01.png)

A proposta para solucionar este problema é de criar uma conexão encapsulada através
de um servidor VPN(*Virtual Private Network*), dessa forma é possível mascarar o tráfego
proveniente do nosso computador.

No exemplo abaixo o tráfego em túnel é uma conexão criptografada que torna impossível
a leitura nítida das informações que trafegam:

![Acesso seguro](/images/vpn-02.png)

[OpenVPN](http://openvpn.net/), ou (*Open Virtual Private Network*) é a ferramenta
que utilizaremos para criar o nosso túnel de rede, ele faz uso do [OpenSSL](https://www.openssl.org/)
para criptografar todo o tráfego e fornecer uma conexão segura entre as máquinas,
(cliente/servidor).

Para esse exemplo, vou utilizar uma VPS com Ubuntu 12.04 LTS.

    123.456.789.12 -> representa o ip da minha máquina local.
    111.222.333.44 -> representa o ip da VPS

Antes de começar, atualize os repositórios e pacotes instalados, em seguida instale
o OpenVPN:

```bash
ubuntu@infoslack:~$ sudo apt-get update
ubuntu@infoslack:~$ sudo apt-get upgrade
ubuntu@infoslack:~$ sudo apt-get install openvpn
```

O OpenVPN possui ferramentas relacionadas à criptografia o **easy-rsa**, por padrão
encontra-se no diretório **/usr/share/doc/openvpn/examples/easy-rsa/**, precisamos
dele em **/etc/openvpn**:

```bash
ubuntu@infoslack:~$ sudo cp -R /usr/share/doc/openvpn/examples/easy-rsa/ \
/etc/openvpn
```

Agora, precisamos gerar a infraestrutura de chave pública, entre no diretório
**/etc/openvpn/easy-rsa/2.0/**, crie um link simbólico chamado **openssl.cnf** de
**openssl-1.0.0.cnf**, edite o script **vars** alterando a linha
*export KEY_SIZE=1024* para *export KEY_SIZE=2048* pois não queremos gerar chaves
de 1024 bits, por fim execute o script **vars**:

```bash
ubuntu@infoslack:~$ cd /etc/openvpn/easy-rsa/2.0/
ubuntu@infoslack:/etc/openvpn/easy-rsa/2.0$ sudo ln -s openssl-1.0.0.cnf \
openssl.cnf
ubuntu@infoslack:/etc/openvpn/easy-rsa/2.0$ . /etc/openvpn/easy-rsa/2.0/vars
```

Após rodar o script **vars** ele retornará a seguinte mensagem:
**NOTE: If you run ./clean-all, I will be doing a rm -rf on /etc/openvpn/easy-rsa/2.0/keys**.

Execute o script **clean-all** e em seguida o **build-ca** para gerar os certificados,
preencha as informações que forem solicitadas:

```bash
$ . /etc/openvpn/easy-rsa/2.0/clean-all
$ . /etc/openvpn/easy-rsa/2.0/build-ca
Generating a 2048 bit RSA private key
.......................................................................+++
.+++
writing new private key to 'ca.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [US]:
State or Province Name (full name) [CA]:
Locality Name (eg, city) [SanFrancisco]:
Organization Name (eg, company) [Fort-Funston]:Infoslack-VPN
Organizational Unit Name (eg, section) [changeme]:
Common Name (your name or your server hostname) [changeme]:infoslack-server
Name [changeme]:Admin
Email Address [mail@host.domain]:root@initsec.com
```

Agora basta gerar a chave privada do servidor e o certificado para ser usado em
nosso cliente de VPN, ao criar as chaves, preencha os dados que forem solicitados:

```bash
$ . /etc/openvpn/easy-rsa/2.0/build-key-server server
$ . /etc/openvpn/easy-rsa/2.0/build-key infoslack-client
```

Falta gerar o **Diffie Hellman Parameters** que é o método utilizado pelo OpenVPN
para troca de chaves, ele irá gerar um arquivo *.pem*, essa tarefa demora um pouco:

```bash
$ . /etc/openvpn/easy-rsa/2.0/build-dh
```

Criamos todas as chaves, precisamos movê-las para o local correto:

```bash
ubuntu@infoslack:/etc/openvpn/easy-rsa/2.0$ cd keys/
ubuntu@infoslack:/etc/openvpn/easy-rsa/2.0/keys$ cp ca.crt ca.key \
server.crt server.key dh2048.pem /etc/openvpn/
```

Falta pouco, precisamos dos arquivos de configuração que serão utilizados pelo
server e cliente na comunicação:

```bash
$ cd /usr/share/doc/openvpn/examples/sample-config-files
$ gunzip -d server.conf.gz
$ cp server.conf /etc/openvpn/
```

Separe os arquivos de cliente para serem enviados a sua máquina:

```bash
$ mkdir ~/client
$ cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf \
~/client/
$ cd /etc/openvpn/easy-rsa/2.0/keys/
$ cp ca.crt infoslack-client.crt infoslack-client.key ~/client/
```

Edite o arquivo de configuração **client.conf** e altere as informações
referentes ao endereço do server e as chaves:

    #mude para o ip/domínio do servidor:
    remote my-server-1 1194 -> 111.222.333.44 1194

    #mude para o nome dos arquivos gerados:
    dh dh1024.pem -> dh2048.pem
    ca ca.crt
    cert client.crt -> infoslack-client.crt
    key client.key -> infoslack-client.key

Compacte o diretório com os arquivos de cliente e envie para sua máquina:

```bash
$ tar -czvf client.tar.gz client/
$ scp client.tar.gz daniel@123.456.789.12:/opt
```

Antes de inicializar o serviço do OpenVPN no server, vamos criar um
redirecionamento de tráfego da internet para a rede privada da VPN, para isso
edite o arquivo **server.conf** em **/etc/openvpn** e descomente a linha:
`;push "redirect-gateway def1 bypass-dhcp"`.

Crie um script para configurar o iptables e encaminhar o tráfego através da VPN:

```shell-session
echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -j REJECT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A INPUT -i tap+ -j ACCEPT
iptables -A FORWARD -i tap+ -j ACCEPT
```

Basicamente o script habilita o módulo **ip_forward** no kernel e cria uma rota
que envia o tráfego de internet da VPS para o nosso túnel criptografado.

Inicialize o serviço do OpenVPN e execute o script criado:

```bash
$ sudo service openvpn start
$ sh ~/vpn-route
```

Verifique com o comando **ifconfig** a existência de uma nova interface chamada
**tun0**.

Supondo que sua máquina cliente seja linux e com o OpenVPN instalado,
descompacte os arquivos de configuração de client gerados no server e execute:

```bash
$ mkdir /opt/openvpn
$ tar zxvf /opt/client.tar.gz -C /opt/openvpn
$ openvpn --config /opt/openvpn/client/client.conf
```

Caso utilize Mac ou Windows verifique as ferramentas [OpenVPN GUI](http://openvpn.se/)
e [tunnelblick](https://code.google.com/p/tunnelblick/).

Após inicializar o cliente OpenVPN a conexão com a VPN será inicializada e você
receberá uma mensagem informando:
**Initialization Sequence Completed**, agora podemos testar a nossa conexão com
a VPN e ver se o redirecionamento de tráfego está ok. Para isso utilize o [httpbin](https://github.com/kennethreitz/httpbin):

```bash
$ curl httpbin.org/ip
{
  "origin": "111.222.333.44"
}
$
```

Se o ip retornado for o da sua VPS, significa que o redirecionamento de tráfego
da VPN está funcionando perfeitamente. Outro teste poderia ser feito utilizando o
[ifconfig.me](http://ifconfig.me/):

```bash
$ curl ifconfig.me
111.222.333.44
```

Com a VPN sua conexão estará um pouco mais segura e você não precisará se
preocupar com as armadilhas das redes wi-fi públicas. =)
