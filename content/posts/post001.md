---
title: Bcachefs on Guix
date: 2024-11-10
tags: [guix, bcachefs]
---

At least until 2024-11-10, #Guix support for #bcachefs is not optimal. 

I [patched](https://issues.guix.gnu.org/74273) Guix for supporting multi-device specifications.

I mount the file-system in this way:

```scheme
  (file-systems (cons*
          (file-system
             (mount-point "/")
             (device (uuid "c1b801d4-ab86-4e62-b0d2-f8ef7d424879"))
             (type "btrfs")
             (options "compress=zstd"))

          (file-system
             (mount-point "/mnt/bcachefs")
             (type "bcachefs")
             (device "/dev/sdb:/dev/sdc:/dev/sdd")
             (mount-may-fail? #t) ; TODO temporary hack, otherwise the Guix boot process can be blocked in case of errors on some device
             (options "degraded") ; accept also recoverable errors,
                                  ; otherwise the system is blocked
          )

          %base-file-systems)))
```

- bcachefs on root file-system is not yet supported, so I use btrfs;
- the boot process in Guix must read the gnu store, that it is on btrfs;
- I created symbolic links from the root btrfs file-system to the bcachefs file-system mounted on `/mnt/bcachefs`, e.g. `/home`, `/srv`, `/var/opt`;
- I didn't touched system directory needed at boot, like `/var/lib`;
- I disabled the calling of `bcachefs fsck` from `bcachefs-tools`, because it is automatically done from the kernel bcachefs, and there can be mismatch between the versions of the two;


