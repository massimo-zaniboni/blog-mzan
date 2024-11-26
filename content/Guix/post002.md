Title: Using StGit for contributing to Guix
Date: 2024-11-08
tags: guix

[StGit (i.e. Stacked Git)](https://stacked-git.github.io) is a command-line application for mixing user-level patches with upstream changes of a repository. I use it for managing my [private Guix repository](https://blog.dokmelody.org/mzan/how-to-maintain-a-private-guix-fork).  

## Configuration

`git send-email` utility must be installed. It is part of `git` package, but not the default output but the `git:send-email` output. In the system configuration it is something like this:

```
  (packages
       (list git
             `(,git "send-email")
             stgit-2 ; Stackeg Git 
   ))
```

`git send-email` must be configured using the git guidelines.

## Sending the patch

```
$ stg edit my-patch-name
$ stg email send --annotate my-patch-name
```

Informal notes can be specified after the header of the commit message, after the `---`.  Something like

```
From 2142f04036761f24a045a176098b1d0f958ce3bf Mon Sep 17 00:00:00 2001
Message-ID: <2142f04036761f24a045a176098b1d0f958ce3bf.1731110493.git.mzan@dokmelody.org>
From: Massimo Zaniboni <mzan@dokmelody.org>
Date: Fri, 8 Nov 2024 23:31:48 +0100
Subject: [PATCH] Support for bcachefs-like multi-device file-systems.

Support multi-device like "/dev/sda:/dev/sdb".

Change-Id: Iddd9c31f8c083a55e7a1fb193e7bbfb396e2def6
---
These are informal notes to send to the mailing list.

 gnu/build/file-systems.scm  | 49 ++++++++++++++++++++++++++++---------
 gnu/machine/ssh.scm         | 23 ++++++++++++++++-
 gnu/system/file-systems.scm | 15 ++++++++++++
 guix/scripts/system.scm     | 25 ++++++++++++++++++-
 4 files changed, 98 insertions(+), 14 deletions(-)

diff --git a/gnu/build/file-systems.scm b/gnu/build/file-systems.scm
index 41e1c9e..7dba7e0 100644
--- a/gnu/build/file-systems.scm
+++ b/gnu/build/file-systems.scm
@@ -9,6 +9,7 @@
```

## Updating the patch

Assuming that the patch number assigned from Guix issue manager is 74273 and the revision is 2 (i.e. the first change, after the initial commit), the command to use for sending a new revision of `my-patch-name` is:

```
stg email send --annotate -v2 --to=74273@debbugs.gnu.org my-patch-name
``` 


