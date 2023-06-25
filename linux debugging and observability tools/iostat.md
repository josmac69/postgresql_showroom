# iostat

Standard command: `iostat -x | grep -v '^loop'`


**iostat** (input/output statistics) is a command-line tool for monitoring system input/output device loading by observing the time the devices are active in relation to their average transfer rates. In other words, it's a tool that can be used to monitor the performance of your storage devices (like hard drives). It's part of the `sysstat` package.

The iostat command generates reports that can be used to change system configuration to better balance the input/output load between physical disks.

Here's a simple example of how you might use iostat:

```bash
iostat
```

Running `iostat` without any options will display the CPU utilization report and the Device Utilization report. The first line of the CPU utilization report contains statistics since system startup. Subsequent lines of output (if any) are statistics since the last report.

The Device Utilization report provides statistics on a per physical device or partition basis. The report shows the number of transfers per second (`tps`), the amount of data read and written in kilobytes (`Blk_read/s` and `Blk_wrtn/s`), and the amount of time the device is busy (`%util`).

You can also specify a time interval, like this:

```bash
iostat 5
```

This command will display a report every 5 seconds. This can be useful for monitoring changes over time.

Here's another example:

```bash
iostat -d /dev/sda 5
```

This command will display a device utilization report for the `/dev/sda` device every 5 seconds.

The `-x` option can be used to display extended statistics, like this:

```bash
iostat -x
```

This command will display extended statistics, including things like the average queue size (`avgqu-sz`), the average wait time (`await`), and the average service time (`svctm`).

Remember, iostat is a powerful tool for monitoring the performance of your storage devices. It can help you identify bottlenecks and tune your system for better performance.

****

What each of those columns represents in the `iostat` output:

- `r/s`: The number of read requests that were issued to the device per second.
- `rkB/s`: The number of kilobytes read from the device per second.
- `rrqm/s`: The number of read requests that were merged per second.
- `%rrqm`: The percentage of read requests that were merged.
- `r_await`: The average time (in milliseconds) for read requests issued to the device to be served.
- `rareq-sz`: The average size (in kilobytes) of read requests that were issued to the device.

- `w/s`: The number of write requests that were issued to the device per second.
- `wkB/s`: The number of kilobytes written to the device per second.
- `wrqm/s`: The number of write requests that were merged per second.
- `%wrqm`: The percentage of write requests that were merged.
- `w_await`: The average time (in milliseconds) for write requests issued to the device to be served.
- `wareq-sz`: The average size (in kilobytes) of write requests that were issued to the device.

- `d/s`: The number of discard requests that were issued to the device per second.
- `dkB/s`: The number of kilobytes discarded from the device per second.
- `drqm/s`: The number of discard requests that were merged per second.
- `%drqm`: The percentage of discard requests that were merged.
- `d_await`: The average time (in milliseconds) for discard requests issued to the device to be served.
- `dareq-sz`: The average size (in kilobytes) of discard requests that were issued to the device.

- `f/s`: The number of flush requests that were issued to the device per second.
- `f_await`: The average time (in milliseconds) for flush requests issued to the device to be served.

- `aqu-sz`: The average queue length of the requests that were issued to the device.
- `%util`: Percentage of CPU time during which I/O requests were issued to the device (bandwidth utilization for the device). Device saturation occurs when this value is close to 100%.

These statistics can be very useful for diagnosing performance issues with your storage devices.

****

The "loop" devices you're seeing are loopback devices in Linux. A loopback device is a special, virtual device that can be used to mount a file system image, such as an ISO file, as if it were a physical device.

Here's a simple example: if you have an ISO file (which is an image of a CD or DVD), you can use a loopback device to "mount" that ISO file. Once it's mounted, you can access the files in the ISO as if it were a physical CD or DVD inserted into your computer.

The numbers you're seeing (like `loop0`, `loop1`, etc.) are just identifiers for different loopback devices. You can have multiple loopback devices, each one associated with a different file system image.

As for whether you should pay attention to them, it depends on what you're trying to do. If you're just looking at general I/O statistics for your physical hard drives, you can probably ignore the loopback devices. But if you're troubleshooting an issue with a mounted file system image, the loopback devices might be relevant.

In general, loopback devices don't represent physical hardware and don't contribute to the load on your storage devices in the same way that reading/writing to a physical hard drive would. So if you're monitoring I/O performance, you might want to focus on the devices that represent your actual hard drives.

****

Loop devices in Linux are virtual devices that turn files into block devices. This is useful for a variety of purposes, such as mounting disk images (like ISO files) as if they were real disks.

To see what files are associated with each loop device, you can use the `losetup` command. Here's an example:

```bash
losetup -a
```

This command will display a list of all loop devices and the files they're associated with.

As for whether you should pay attention to them, it depends on what you're trying to do. If you're just looking at general I/O statistics for your physical hard drives, you can probably ignore the loopback devices. But if you're troubleshooting an issue with a mounted file system image, the loopback devices might be relevant.

