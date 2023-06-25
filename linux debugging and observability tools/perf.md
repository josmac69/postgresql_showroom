# perf

install perf: `sudo apt install linux-tools-common linux-tools-generic linux-tools-5.19.0-45-generic`

* perf stat ls
```
$ sudo perf stat ls

 Performance counter stats for 'ls':

              0,45 msec task-clock                #    0,484 CPUs utilized
                 0      context-switches          #    0,000 /sec
                 0      cpu-migrations            #    0,000 /sec
               103      page-faults               #  227,738 K/sec
         2.062.113      cycles                    #    4,559 GHz
         2.190.408      instructions              #    1,06  insn per cycle
           409.699      branches                  #  905,865 M/sec
            11.916      branch-misses             #    2,91% of all branches

       0,000935384 seconds time elapsed

       0,000975000 seconds user
       0,000000000 seconds sys
```
