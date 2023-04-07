# Casts


Sometimes you get message like this

*ERROR:  cannot cast type … to …*

Which of course means that PostgreSQL does not know how to cast directly one type into another. In all these cases you can use cast to TEXT – it works always. And from TEXT you can also cast into all PG types.

For example if you want to use system column xmin you cannot use it directly in ORDER BY and you need to cast it into some different type.

Cast to INT or BIGINT will also not work.

So you have to do this:

```
xmin::text::bigint
```

But this type of cast is so-called “legacy” and will be probably abandoned in the future. Right appropriate cast looks like this:

```
CAST(CAST(xmin as TEXT) as BIGINT)
```
