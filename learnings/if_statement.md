# IF statements - useful constructs

* Use SELECT count in IF command:
```
IF (SELECT count(*) FROM table WHERE column IS NULL)>0 THEN
...
END IF
```

* Use EXISTS in IF condition
```
IF EXISTS( select ... from table where ....) THEN
...
END IF;
```
