# pl/sh language – small hints

Maybe many people do not like this idea accessing linux shell from the database but if you the “affected one” who needs to use it – here are some hints.

* Extension plsh seems maybe a little bit outdated but it still works even on pg 9.6 (tested 2016/12) – so install it following instructions in repo – [https://github.com/petere/plsh](https://web.archive.org/web/20210919024853/https://github.com/petere/plsh)
* if you really need to do some “ugly” things you can even add postgres user among users allowed to use “sudo” command – see “visudo” part here – [http://kingratlinux.blogspot.de/2014/07/add-plsh-to-postgres-93.html](https://web.archive.org/web/20210919024853/http://kingratlinux.blogspot.de/2014/07/add-plsh-to-postgres-93.html)
  * but be aware – this can cause disasters ! So think twice about it…
* run in pg: create extension plsh;
* basic examples of procedures are described in README in repo so no need to copy them around – just some small notes:
  * if your procedure returns some value your shell code must contain at least one echo at the end
  * safest data type to return from shell is pg type “text”
  * but also usual types integer, numeric, date etc. can be returned – you simply echo in shell part string or number which can be on pg level casted into desired type without errors and that’s it
  * looks like function cannot return multiple rows using “RETURNS SETOF …” or multiple values using “RETURNS RECORD …” but it can return text with multiple lines separated by “newline” character
  * if you have more “echo” commands in your sh function then on pg level you will see text with multiple lines inside returned value – not multiple returned rows from a function
* Some shell commands display some informations into stderr although the do not end with error – for example “curl” sends statistics about catched bytes and time into stderr. Extension pl/sh checks for stderr output and if it finds something then displays is as error message and stops. So for some commands you will need to add “2>&1” or “2>/dev/null” depends on whether you need that message or not.
