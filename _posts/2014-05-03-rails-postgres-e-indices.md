---
layout: post
title: "Rails, PostgreSQL e o uso de índices"
description: "Aprenda a trabalhar com índices no PostgreSQL e Ruby on Rails"
category: development
keywords: rails, postgresql, indexação, desenvolvimento, software
---

### Update:

"Vale lembrar que campos com índices únicos tratam maiúsculas e minúsculas
como caracteres diferentes. Um campo username com índice único irá aceitar,
por exemplo, os valores `john`, `John` e `JOHN` como valores únicos.
Para evitar que isso aconteça, use a extensão citext."

Dica do [Nando](https://twitter.com/fnando)

Confira em: [simplesideias.com.br](http://simplesideias.com.br/usando-campos-case-insensitive-no-postgresql)

----

Ultimamente tenho feito alguns trabalhos que envolvem "melhorias" de software,
ajustes para aumentar o desempenho em produção ou simplesmente para fazer
funcionar da forma correta.

As melhorias abordam coisas simples como fazer uso correto do ActiveRecord,
utilizar da melhor forma os recursos da tecnologia escolhida. Em boa parte dos
casos o uso de índices e correções no uso do ActiveRecord já resolve bastante.

### Para que serve um índice ?

Em banco de dados, um índice é uma referência utilizada para otimizações, isso
permite que um registro seja localizado de forma mais rápida em uma consulta.

O PostegreSQL [possui várias opções de índices](http://www.postgresql.org/docs/9.3/static/indexes.html), porém o tipo mais comumente
utilizado é o [B-tree](http://en.wikipedia.org/wiki/B-tree).

### Índice de chave primária

É comum adicionarmos um índice para as chaves primárias de nossas tabelas, mas
no caso do PostgreSQL isso é feito de forma automática, por tanto não precisamos
criar de forma explícita.

Quando geramos uma migration:

{% highlight ruby %}
class CreateUser < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
{% endhighlight%}

A saída no psql será a seguinte:

{% highlight sql linenos %}
hfh_development=# \d users

                        Table "public.users"

id      integer   not null default nextval('users_id_seq'::regclass)
name    character varying(255)  not null
email   character varying(255)  not null

Indexes:
"users_pkey" PRIMARY KEY, btree (id)
{% endhighlight %}

Na linha 10 podemos ver que o PostgreSQL adicionou o índice B-tree na chave
primária, neste exemplo no campo `id`.

### Aplicações Rails com baixo desempenho por falta de índices

Imagine um fórum que possui muitas perguntas organizadas por categorias, sem o
uso de índices a busca seria bastante lenta de ser realizada.
A falta de índices em chaves estrangeiras é um dos problemas mais comuns que
provocam o baixo desempenho em apps Rails.

O uso de índices em relacionamentos poderia ser dessa forma:

{% highlight ruby %}
class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string :title
      t.text :content
      t.belongs_to :category, index: true

      t.timestamps
    end
  end
end
{% endhighlight %}

Ao adicionar `index: true` na migration para o relacionamento, o PostgreSQL
gerou um índice chamado `index_questions_on_category_id` que aponta para o
campo `category_id`:

{% highlight sql %}
hfh_development=# \d questions

                Table "public.questions"

id          integer   not null default nextval('questions_id_seq'::regclass)
title       character varying(255)  not null
content     text                    not null
category_id integer                 not null

Indexes:
"questions_pkey" PRIMARY KEY, btree (id)
"index_questions_on_category_id" btree (category_id)
{% endhighlight %}

Isso faz toda diferença nas consultas feitas pela aplicação.

### Evitando registros duplicados

Pois bem, em alguns dos trabalhos encontrei o problema de registros duplicados
no banco de dados, isso normalmente ocorre por falta do uso de índices para impor
unicidade no valor salvo (apenas validar no Rails não vai resolver o problema).

Imagine dois usuários tentando fazer um cadastro utilizando o mesmo e-mail e a
sua aplicação possuí apenas o `validates_uniqueness_of` no model para validar a
unicidade do e-mail.

Ao submeterem o formulário preenchido ao mesmo tempo, o Rails vai verificar na
tabela de usuários para saber se já existe algum registro com o e-mail fornecido
, não encontrando nada ele responde que pode prosseguir e acaba permitindo o
registro de 2 e-mails iguais mandando a validação de unicidade pro espaço.

Para evitar isso, podemos fazer uso de índices de unicidade
{% highlight ruby %}
class CreateUser < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
{% endhighlight%}

Adicionando o `unique: true` na migration o PostgreSQL irá gerar o seguinte
índice no banco:

{% highlight sql linenos %}
hfh_development=# \d users

                        Table "public.users"

id      integer   not null default nextval('users_id_seq'::regclass)
name    character varying(255)  not null
email   character varying(255)  not null

Indexes:
"users_pkey" PRIMARY KEY, btree (id)
"index_users_on_email" UNIQUE, btree (email)
{% endhighlight %}

Agora é possível garantir a integridade dos dados e evitar a duplicação de
registros.

### Índices parciais

Basicamente um índice parcial é definido por uma expressão condicional, em
outras palavras ele faz uso da cláusula `where`, dessa forma ele é construído
apenas com as informações que satisfazem a condição criada.

Imagine que no aplicativo de fórum temos uma tabela para perguntas e nessa
tabela contém um campo para marcar perguntas como respondidas (true) ou não
respondidas (false), podemos criar um índice parcial para filtrar as não
respondidas e melhorar o desempenho na consulta para exibi-las:

{% highlight ruby %}
class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string :title
      t.text :content
      t.boolean :answered, default: false

      t.timestamps
    end

    add_index :questions, :answered, where: "answered = false"
  end
end
{% endhighlight %}

O PostegreSQL vai gerar o seguinte índice:

{% highlight sql %}
hfh_development=# \d questions

                Table "public.questions"

id          integer   not null default nextval('questions_id_seq'::regclass)
title       character varying(255)  not null
content     text                    not null
answered    boolean                 default false

Indexes:
"questions_pkey" PRIMARY KEY, btree (id)
"index_questions_on_answered" btree (questions) WHERE answered = false
{% endhighlight %}

Espero que tenha ficado claro a importância do uso de índices.
Happy Hacking ;)

#### Referências

- [http://guides.rubyonrails.org/migrations.html](http://guides.rubyonrails.org/migrations.html)
- [http://www.postgresql.org/docs/9.3/static/indexes.html](http://www.postgresql.org/docs/9.3/static/indexes.html)
- [http://www.postgresql.org/docs/9.3/static/indexes-ordering.html](http://www.postgresql.org/docs/9.3/static/indexes-ordering.html)
- [http://www.postgresql.org/docs/9.3/static/indexes-unique.html](http://www.postgresql.org/docs/9.3/static/indexes-unique.html)
- [http://www.postgresql.org/docs/9.3/static/indexes-partial.html](http://www.postgresql.org/docs/9.3/static/indexes-partial.html)
