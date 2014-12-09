---
layout: post
comments: true
title: "CGroups and No Space"
date: 2014-12-09 07:50:00
tags: [Tips, Linux, Troubleshoot]
---

I've been working with [Control Groups][cgroups] recently to investigate a performance issue. I have not found a
solution yet but will post again if that does happen! As for CGroups, I came across an issue that although simple
if I just read the documentation, didn't seem obvious by the error:

```bash
[Errno 28] No space left on device
```

<!--more-->

## Solution

So other example errors could be as follows which all boil down to "No space left on device" and just depends on how
you were creating the CGroups:

```bash
[Errno 28] No space left on device
bash: echo: write error: No space left on device
Error changing group of pid 1234: No space left on device
```

This seemed really odd because I was pretty sure I didn't consume all my space on the system. Looking at the system
the following was there:

```bash
$ df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/md0              9.9G  1.6G  7.8G  18% /
/dev/md1              9.9G  1.2G  8.2G  13% /var
/dev/md3              882G   96G  742G  12% /export
tmpfs                 512M  144K  512M   1% /tmp
```

There's clearly space everywhere! But what I didn't realize was that I didn't initialize CGroups correctly. The dumb
me did not read the big bold starred section in the [documentation][cpuset] for `cpuset` under **Mandatory parameters**
which state:

> Some subsystems have mandatory parameters that must be set before you can move a task into a cgroup which uses
> any of those subsystems. For example, before you move a task into a cgroup which uses the `cpuset` subsystem,
> the `cpuset.cpus` and `cpuset.mems` parameters must be defined for that cgroup.

Here is how my CGroup was defined (this is a general format, please read documentation on how to actually change
things if you are interested in using CGroups):

```
group main_process {
   cpuset {
      cpuset.cpus = 0-6;
   }
}
```

Upon trying to add the process to the CGroup, I encountered the "No space left on device" error. Notice how I didn't
follow directions? That's okay, at least I went back to read the documentation afterward so I think I redeemed
myself for a bit. All I had to do was make sure to define `cpuset.mems` and the error would disappear! Apparently
this incorrect initialization causes the CGroup mount to not work correctly! The new modified CGroup definition
should be as follows:

```
group main_process {
   cpuset {
      cpuset.cpus = 0-6;
      cpuset.mems = 0;
   }
}
```

Now everything worked correctly, I could add my process to the CGroup and continue on with my work! I'm not exactly
sure why this error occurs but I suspect that it has to do with the fact that control groups must be mounted in
order to interact and define them. This mounting makes the portion of CGroups data as if it were a separate
filesystem and without properly initializing it, it seems to cause errors when trying to interact with it.

If you have had experience with CGroups or know more, please enlighten as I am curious. I will try to dig up what
I can to learn more and post if I find anything but I can't promise anything as the Linux world is so complex.

[cgroups]: https://www.kernel.org/doc/Documentation/cgroups/cgroups.txt
[cpuset]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Resource_Management_Guide/sec-cpuset.html
