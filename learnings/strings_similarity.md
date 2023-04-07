# Similarity of two strings – experiences

Basically there 2 very good extension available if you need to check how similar are 2 strings.

* [pg_trgm](https://web.archive.org/web/20200710070837/https://www.postgresql.org/docs/current/static/pgtrgm.html) – extension is part of standard installation and contains “trigram comparison algorithm”.
* [pg_similarity](https://web.archive.org/web/20200710070837/https://github.com/eulerto/pg_similarity) – extension is available on github and it is easy to install it.

I checked both because I had task to compare some data and here are some experiences.

* generally pg_trgm seems to be better integrated with PostgreSQL:
  * it allows you to use gin or gist indexes
  * it allows you to use parallel workers for processing
  * therefore “similarity” function was in my tests much quicker then functions from pg_similarity extension
  * tests show me that for my purposes trigram algorithm was the best choice – I had to compare always 2 strings which could contain some same and some different words but in random order
* on the other hand pg_similarity extension implements a big variety of functions – if you need different algorithm then just trigram.
