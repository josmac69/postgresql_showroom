# Show source code of trigger function
Because I found with surprise that DataGrip shows irregular version of trigger function’s source code and pgAdmin 4 somehow refuses to show it at all (claiming internal server error) I had to find some other way how to access it.


in psql:
```
\dft – shows all trigger functions names
\dS <tablename> – shows names of triggers on given table
\df+ <functionname> – shows source code of trigger function
```
in GUI:
```
select pg_get_functiondef('functionname'::regproc);
```
