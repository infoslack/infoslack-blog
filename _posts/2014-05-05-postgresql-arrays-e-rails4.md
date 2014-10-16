---
layout: post
title: "Utilizando o recurso de arrays do PostgreSQL com Rails 4"
description: "Aproveite o recurso de arrays do PostgreSQL no Rails 4"
category: development
keywords: rails4, postgresql, arrays, desenvolvimento, software
---

O [PostgreSQL](http://www.postgresql.org/docs/9.3/static/arrays.html) permite que registros sejam armazenados como arrays
multidimensionais com o comprimento variável e esse recurso pode ser utilizado
com o [Rails 4](https://github.com/rails/rails/pull/7547).

Imagine que em um e-commerce cada produto cadastrado, deve pertencer a uma
categoria, o recurso de arrays deve ser ativo na migration com a opção
`array: true` onde por padrão é atribuído um array vazio. Nossa migration
ficaria assim:

{% highlight ruby %}
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :description
      t.string :categories, array: true, default: []

      t.timestamps
    end
  end
end
{% endhighlight%}

Verificando com o psql podemos ver o tipo `[]` criado pelo Postgres que indica
que a coluna criada será tratada como um array:

{% highlight sql %}
store_development=# \d products

                     Table "public.products"

id  integer not null default nextval('products_id_seq'::regclass)
name        character varying(255)
description character varying(255)
categories  character varying(255)[]  default '{}'::character varying[]

Indexes:
"products_pkey" PRIMARY KEY, btree (id)
{% endhighlight%}

No rails console podemos testar o comportamento do que foi gerado:

{% highlight ruby %}
irb(main)> Product.create(
              name: "Book Rails",
              categories:["ruby", "rails", "dev"]
           )

(0.2ms)  BEGIN SQL (0.4ms)  INSERT INTO "products"
("categories", "created_at", "name", "updated_at")

VALUES ($1, $2, $3, $4) RETURNING "id"
[["categories", "{\"ruby\",\"rails\",\"dev\"}"],
["created_at", "2014-05-05 18:33:58.031321"],
["name", "Book Rails"],
["updated_at", "2014-05-05 18:33:58.031321"]]
(9.3ms) COMMIT

=> #<Product:0x007f3f00bee498> {
            :id => 2,
          :name => "Book Rails",
    :categories => [
        [0] "ruby",
        [1] "rails",
        [2] "dev"
    ],
    :created_at => Mon, 05 May 2014 15:33:58 BRT -03:00,
    :updated_at => Mon, 05 May 2014 15:33:58 BRT -03:00
}
{% endhighlight%}

Voltando ao psql vamos ver como os dados foram armazenados na tabela:

{% highlight sql %}
store_development=# select * from products;

id |    name    |    categories   |
---+------------+-----------------+
2  | Book Rails | {ruby,rails,dev} |

(1 row)
{% endhighlight%}

As consultas podem ser feitas normalmente com o ActiveRecord, nada muda:

{% highlight ruby %}
irb(main)> Product.where("'ruby' = ANY (categories)")

Product Load (1.0ms)
  SELECT "products" * FROM "products"  WHERE ('ruby' = ANY (categories))

ActiveRecord::Relation [
  Product id: 2,
  name: "Book Rails",
  categories: ["ruby", "rails", "dev"],
  created_at: "2014-05-05 18:33:58",
  updated_at: "2014-05-05 18:33:58"
]
{% endhighlight%}

Explore ao máximo os recursos e confira as referências.

Happy Hacking ;)

### Referências

- [http://www.postgresql.org/docs/9.3/static/arrays.html](http://www.postgresql.org/docs/9.3/static/arrays.html)
- [https://github.com/rails/rails/pull/7547](https://github.com/rails/rails/pull/7547)
