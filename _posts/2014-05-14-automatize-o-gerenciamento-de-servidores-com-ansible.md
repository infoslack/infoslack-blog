---
layout: post
title: "Automatize o gerenciamento de servidores com Ansible"
description: "Permita que o Ansible gerencie os seus servidores"
category: devops
keywords: server, linux, unix, services, servidor, ansible, gerenciamento, ssh, provisionamento, devops
---

Configurar um servidor para ser utilizado em produção é uma tarefa um pouco
complexa e que demanda tempo, mas isso pode ser automatizado de forma simples
e executado rapidamente com [Ansible](http://www.ansible.com/).

Ansible é uma ferramenta open source de gerenciamento de configurações, escrita
em Python serve para automatizar suas tarefas de provisionamento de servidores,
a curva de aprendizagem é mínima e tudo o que ele necessita para funcionar é
ter acesso **SSH** ao servidor e fazer a leitura dos Playbooks (livros de receitas)
que são arquivos de provisionamento escritos em [YAML](http://www.yaml.org/).

### O setup

Imagine que temos a tarefa de configurar um servidor de produção para uma
aplicação Rails, logo precisamos instalar o Ruby, Nginx, criar um usuário para
deploy, adicionar regras de firewall, etc.

Tudo isso poderia ser feito manualmente via SSH, porém o que vamos fazer é
delegar essa tarefa ao Ansible, neste post veremos um exemplo de como seria a
automatização do processo para instalar o web server **Nginx**.

Primeiro precisamos instalar o Ansible na nossa máquina local, isso pode ser
feito via **pip**:

```bash
$ sudo easy_install pip
$ sudo pip install ansible
```

Ou se preferir instalar pelo fonte faça:

```bash
$ git clone git@github.com:ansible/ansible.git
$ cd ansible
$ sudo python setup.py install
```

Supondo que temos acesso SSH ao servidor remoto que vamos configurar e que o
mesmo já está com a nossa chave pública adicionada ao `authorized_keys`, vamos
executar nosso primeiro teste com o Ansible.

O Ansible faz uso de um arquivo chamado `hosts`, esse arquivo deve conter o
nome ou ip do servidor que queremos configurar:

```text
server01
server02
server03
```

ou

```text
192.168.10.1
192.168.10.2
192.168.10.3
```

No `hosts` é possível também separar os servidores em grupos, por exemplo:

```text
[application]
server01

[database]
server02
server03
```

Por padrão o arquivo `hosts` fica em `/etc/ansible/hosts` eu gosto de manter o
arquivo separado nas receitas que utilizo.

Para o nosso primeiro teste, podemos criar o arquivo `hosts` e adicionar o ip
do nosso servidor:

```bash
$ touch hosts
$ echo "192.168.10.15" > hosts
```

Feito isso podemos executar o comando `ansible` informando o arquivo hosts com
o ip do servidor e executar o módulo `ping` para ver se está tudo ok:

```bash
$ ansible -i hosts -m ping all
192.168.10.15 | success >> {
    "changed": false,
    "ping": "pong"
}
```

Basicamente o que fizemos foi instruir o Ansible a utilizar o [módulo ping](http://docs.ansible.com/ping_module.html) e
testar a comunicação com o servidor remoto para verificar a conectividade.

### Escrevendo receitas

Agora que já verificamos a conectividade do Ansible com nosso servidor remoto,
podemos escrever nosso primeiro [Playbook](http://docs.ansible.com/playbooks.html).
Um Playbook nada mais é do que um conjunto de regras que deverão ser
executadas no servidor remoto.

Para este exemplo vamos montar uma estrutura que deverá conter os nossos
Playbooks com regras para instalar alguns pacotes, a estrutura deverá ficar
parecida com a seguinte:

```bash
├── hosts
├── roles
│   ├── nginx
│   │   └── tasks
│   │       └── main.yml
│   └── ruby
│       └── tasks
│           └── main.yml
└── server.yml
```

Então criaremos um diretório chamado `roles` e dentro dele outro chamado
`nginx`, essa organização é entendida pelo Ansible na hora da execução.

Dentro do diretório `nginx` crie outro chamado `tasks` e um arquivo `main.yml`,
este arquivo deve conter as regras de instalação do nginx:

```bash
$ mkdir -p nginx/tasks
$ touch nginx/tasks/main.yml
```

No arquivo `main.yml` do `nginx` temos as regras para instalação, esse é o
nosso primeiro Playbook:

```yaml
---
- name: Add the key used to Nginx pkg
  apt_key: url=http://nginx.org/keys/nginx_signing.key state=present

- name: Add repository for install Nginx
  copy: src=nginx.list dest=/etc/apt/sources.list.d/

- name: Update packages and install Nginx
  apt: name=nginx update_cache=yes
```

Vamos entender o que está acontecendo, na linha **1** temos o parâmetro `---`
que é obrigatório para que o arquivo seja interpretado como um documento YAML,
no caso do Ansible esse parâmetro só pode estar presente uma vez por arquivo e
sempre no início.

Nas linhas **2,5 e 8** vemos o `- name:` que é usado para descrição de cada
tarefa, basicamente ele funciona como `key: value`.

Na linha **3** vemos o [apt-key:](http://docs.ansible.com/apt_key_module.html) que faz parte de um módulo do ansible para o
comando `apt`, basicamente ele realizará o download do arquivo
`nginx_signing.key` e executará o comando `apt-key add nginx_signing.key`.

A opção [copy:](http://docs.ansible.com/copy_module.html) na linha **6** informa para o ansible copiar um arquivo que
contém os repositórios necessários para o `apt` instalar o Nginx. A opção `src`
indica o source do arquivo que queremos copiar e o `dest` o destino. Nesse
exemplo a nossa estrutura teria mais um diretório dentro de `nginx`:

```bash
$ mkdir nginx/files
$ touch nginx/files/nginx.list
```

O último comando na linha **9** é o [apt:](http://docs.ansible.com/apt_module.html) que recebe como parâmetro o nome do
pacote que queremos instalar `name=nginx` e outro argumento `update_cache=yes`
que seria o mesmo que `apt-get update && apt-get install nginx`.

E para executar nosso playbook, precisamos escrever mais um arquivo, chamado de
`server.yml`:

```yaml
---
- name: Install Server
  hosts: server01
  user: root

  roles:
    - nginx
    - ruby
```

Desta forma o ansible entende quais playbooks ele deve executar para o
`server01`:

```bash
$ ansible-playbook -i hosts server.yml
PLAY [Install Server] ************************************************

GATHERING FACTS ******************************************************
ok: [192.168.10.15]

TASK: [nginx | Add the key used to Nginx pkg] ************************
ok: [192.168.10.15]

TASK: [nginx | Add repository for install Nginx] *********************
ok: [192.168.10.15]

TASK: [nginx | Update packages and install Nginx] ********************
ok: [192.168.10.15]

PLAY RECAP ***********************************************************
192.168.10.15    : ok=4  changed=0  unreachable=0  failed=0
```

Lembra que podemos separar o `hosts` em grupos ? Pois bem, imagine que você
precisa configurar vários servidores, aplicação, banco de dados, cache, backup,
etc. No arquivo `server.yml` os hosts podem ser organizados para executarem
playbooks específicos, por exemplo instalar o **Postgresql** ou o **Memcached**
em servidores diferentes.

Observe a simplicidade do Ansible para descrever as tarefas, o mesmo poderia
ser feito com outros pacotes como o Ruby ou para definir regras de firewall, o
ansible suporta muitos módulos e sua [documentação](http://docs.ansible.com/) é rica em detalhes.

### Finalizando

Agora você pode construir suas regras para automatizar tarefas complexas com o
Ansible. O exemplo que vimos serve apenas como um ponto de partida, explore o
potencial da ferramenta.

Caso tenha interesse, verifique alguns [playbooks que disponibilizei no github](https://github.com/infoslack/simple-ansible).

Happy Hacking ;)

### Referências

- [http://docs.ansible.com/intro_installation.html](http://docs.ansible.com/intro_installation.html)

- [http://docs.ansible.com/](http://docs.ansible.com/)

- [http://docs.ansible.com/playbooks.html](http://docs.ansible.com/playbooks.html)

- [https://github.com/ansible/ansible](https://github.com/ansible/ansible)

- [https://github.com/ansible/ansible-examples](https://github.com/ansible/ansible-examples)

- [https://github.com/leucos/ansible-tuto](https://github.com/leucos/ansible-tuto)
