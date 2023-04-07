# Server process was terminated by signal 9: Killed
If you see in PostgreSQL log something like this:
```
LOG:  server process (PID xxxxx) was terminated by signal 9: Killed
following by termination of other PostgeSQL processes and database going into recovery mode
and you wonder what happend than most probable cause is that process was killed by Linux out-of-memory (oom) killer.
```
Log should show you also terminated statement in next line:
```
DETAIL:  Failed process was running: select ........
```
* If you check /var/log/messages* files you can (maybe) find more.
* Use: grep -i ‘oom’ /var/log/messages*
  * It will show you lines like:  `(….) kernel: postgres invoked oom-killer: gfp_mask=0x280da, order=0, oom_adj=0, oom_score_adj=0`

* If you check given messages file further you can see more details like list of processes from oom kill etc.

But basic problem remains – your machine seems to not have enough memory to run all the tasks.