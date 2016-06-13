---
layout: post
title: "Find, liste os arquivos modificados na última hora"
description: "Encontre todos os arquivos que foram modificados na última hora"
category: shell
keywords: linux, shell, find, unix
---

Usando o `find` para listar os arquivos que foram modificados na última hora:

```bash
$ find . -mtime -1
```

* o `.` é o path para a busca
* `-mtime` parâmetro de tempo
* `-1` lista os arquivos modificados nas últimas 24 horas

**Outras configurações:**

* `-amin` acessado em minutos
* `-atime` acessado em dias
* `-cmin` criado em minutos
* `-ctime` criado em dias
* `-mmin` modificado em minutos

**E ainda temos parâmetros numéricos:**

* `-1` últimas 24 horas
* `-0.5` últimas 12 horas
* `-0.25` últimas 6 horas
* `+3` mais de três dias
