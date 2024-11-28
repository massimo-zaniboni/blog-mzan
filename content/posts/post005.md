---
title: Guix and Guile error messages 
date: 2024-10-28
tags: [guix]
---

Sometime #Guile and #Guix error messages are confusing. I will collect here some of them, as case study. Don't get me wrong: Guile is wonderful and it is OSS.

## Guile limitations

- Racket uses contracts, so the error is signaled at the exact point where something of unexpected is happening, while in Guile one should travel the stack-trace for identifying the real source of the problem;
- Typed Racket recognizes many errors at compile-time, while in Guile mainly at run-time;
- CL has more type annotations in libraries, and (at least in SBCL) they are signaled as warnings during compilation;
- CL run-time uses a stack, while Scheme has continuations, so sometime a proper stack-trace is missing;
- in CL you can inspect also the parameters passed to functions, so it is easier figuring out the problem;

## Guix system reconfigure

```
sudo guix system reconfigure ...

mnt/bcachefs/home/mzan/lavoro/admin/guix/think/config-nonguix.scm:439:10: error: device '/dev/sdb:/dev/sdc:/dev/sdd' not found: No such file or directory
error: Recipe system-reconfigure failed with exit code 1
```
The signaled problem is in this part of the configuration

```
          (file-system
             (mount-point "/mnt/bcachefs")
             (device "/dev/sdb:/dev/sdc:/dev/sdd")
             (type "bcachefs"))
```

Guix does not yet support a bcachefs-like device format. I need to extend Guix. The error message is informative enough for end-users, but it is not optimal for developers wanting to improve Guix, because there is no stack-trace informing in which point Guix is stuck. 

### Solution

I added a unique fixed error-code to generated errors, so the exact point of the error can be found quickly. For example

```
/mnt/bcachefs/home/mzan/lavoro/admin/guix/think/config-nonguix.scm:439:10: error:  #8658 device '/dev/sdb:/dev/sdc:/dev/sdd' not found: No such file or directory
error: Recipe `system-reconfigure` failed with exit code 1
```
In this way the error messages will be still nice for end-users (they don't see an ugly stack-trace), but useful also for developers.

## Guix system reconfigure 

After extending the source code, I tried to reconfigure 

```
 sudo -E ./pre-inst-env guix system reconfigure /home/mzan/lavoro/admin/guix/think/config-nonguix.scm
--keep-going
```
I obtain this
```
Backtrace:
In guix/ui.scm:
  2293:10 19 (run-guix-command _ . _)
In ice-9/boot-9.scm:
  1752:10 18 (with-exception-handler _ _ #:unwind? _ # _)
    152:2 17 (with-fluid* _ _ _)
In guix/status.scm:
    839:4 16 (call-with-status-report _ _)
In ice-9/eval.scm:
    619:8 15 (_ #(#(#(#(#(#(#(#(#(#(#(…) …) …) …) …) …) …) …) …) …) …))
In ice-9/boot-9.scm:
  1752:10 14 (with-exception-handler _ _ #:unwind? _ # _)
In guix/store.scm:
   689:37 13 (thunk)
   1330:8 12 (call-with-build-handler #<procedure 7f7ea628ed80 at g…> …)
  2210:25 11 (run-with-store #<store-connection 256.100 7f7ea61700f0> …)
In ice-9/eval.scm:
   191:27 10 (_ #(#(#<directory (guix scripts system) 7f7ebac0…> …) …))
    619:8  9 (_ #(#(#(#<directory (guix scripts system) 7f7eb…>) …) …))
    619:8  8 (_ #(#(#(#<directory (guix scripts system) 7f7eb…>) …) …))
    619:8  7 (_ #(#(#(#<directory (guix scripts system) 7f7eb…>) …) …))
In srfi/srfi-1.scm:
    634:9  6 (for-each #<procedure 7f7ea4380ac0 at ice-9/eval.scm:3…> …)
In ice-9/eval.scm:
   298:42  5 (_ #(#(#<directory (guix scripts system) 7f7ebac0…> …) …))
    159:9  4 (_ #(#(#<directory (guix scripts system) 7f7ebac0…> …) …))
   223:20  3 (proc #(#(#<directory (guix scripts system) 7f7eb…> …) …))
In unknown file:
           2 (%resolve-variable (7 . devices) #<directory (guix scri…>)
In ice-9/boot-9.scm:
  1685:16  1 (raise-exception _ #:continuable? _)
  1685:16  0 (raise-exception _ #:continuable? _)

ice-9/boot-9.scm:1685:16: In procedure raise-exception:
error: devices: unbound variable
error: Recipe `system-reconfigure` failed with exit code 1
```

The file and position of the error is missing. Also the stack trace is rather incomplete and there are no useful names for functions. I had to check the `devices` variable name in last modified source-code. I found it, but this way of proceeding is far from optimal, and rather stressful. 

### Solution

Probably this needs many improvements to the Guile source code.

## Guix reboot

I rebooted the computer with the new settings. There were an error in the code, and the machine was blocked:

![image](/images/screenshot01.jpg)

In this case I have only praises for Guix:

- the error message reports the exact source-code file and position;
- I easily rebooted using old profiles, and fixed the bug;

## gexp errors

I patched Guix, for recognizing bcachefs multi-device (e.g. "/dev/sda:/dev/sdb:/dev/sdc"). 

```
 ./pre-inst-env guix deploy /home/mzan/lavoro/admin/guix/buildbart/deploy.scm
```

I obtained this confusing error message

```
The following 1 machine will be deployed:
  buildbart

guix deploy: deploying to buildbart...
guix deploy: warning: <machine-ssh-configuration> without a 'host-key' is deprecated
guix deploy: sending 0 store items (0 MiB) to 'buildbart'...
Backtrace:
In ice-9/boot-9.scm:
  1752:10 19 (with-exception-handler _ _ #:unwind? _ # _)
In guix/store.scm:
   689:37 18 (thunk)
   1330:8 17 (call-with-build-handler _ _)
   1330:8 16 (call-with-build-handler #<procedure 7f0503a86630 at g…> …)
In guix/scripts/deploy.scm:
   284:23 15 (_)
In guix/store.scm:
  1437:13 14 (map/accumulate-builds #<store-connection 256.100 7f05…> …)
  1412:11 13 (map/accumulate-builds #<store-connection 256.100 7f05…> …)
   1330:8 12 (call-with-build-handler #<procedure 7f0505de66c0 at g…> …)
In ice-9/boot-9.scm:
  1752:10 11 (with-exception-handler _ _ #:unwind? _ # _)
In guix/scripts/deploy.scm:
    166:6 10 (_)
In guix/store.scm:
  2210:25  9 (run-with-store #<store-connection 256.100 7f050369dd70> …)
In unknown file:
           8 (_ #<procedure 7f05038af060 at ice-9/eval.scm:330:13 ()> …)
In ice-9/eval.scm:
   191:27  7 (_ #(#(#<directory (gnu machine ssh) 7f0505887e60> #) …))
    619:8  6 (_ #(#(#(#<directory (gnu machine ssh) 7f05058…> …) …) …))
In srfi/srfi-1.scm:
   650:11  5 (for-each #<procedure 7f0511893cc0 at ice-9/eval.scm:3…> …)
In ice-9/eval.scm:
   245:16  4 (_ #(#(#<directory (gnu machine ssh) 7f0505887e60> #) #))
In srfi/srfi-1.scm:
   876:18  3 (every1 #<procedure number? (_)> _)
In ice-9/boot-9.scm:
  1685:16  2 (raise-exception _ #:continuable? _)
  1685:16  1 (raise-exception _ #:continuable? _)
  1685:16  0 (raise-exception _ #:continuable? _)

ice-9/boot-9.scm:1685:16: In procedure raise-exception:
In procedure cdr: Wrong type argument in position 1 (expecting pair): #f
mzan@think ~/lavoro/admin/guix/custom-guix-repo$
```

Probably it is a stupid error, and in this case a static type-checking could help, because it seems an error in the params sent to a function. But, for discovering the error in Guile, I need to test the code, figuring out where is the problem.

The error message lacks some info about the correct position on sorce-code, because it is a thunk of code (i.e. a *gexp*) executed on the remote machine. To be fair, sometime Guix is able to indicate the correct position in the source-code of *gexp*, because it can add this meta-info to *gexp* thunks. So I'm doing some FUD.

### Analysis of Guix code

The Guix command line entry point is `guix/ui/guix-main`. It reads the settings passed by my command-line `./pre-inst-env guix ...`. If I want to launch a debugging Guile session, I need to pass these params in some way. 

- from a shell, I asked the position of `guix` with `./pre-inst-env which guix`. In my case it is `/mnt/bcachefs/srv/git/custom-guix-repo/scripts/guix`
- I loaded `guix/ui.scm` in Geiser, the Emacs Guile module 
- I entered in the module with `,module guix ui`
- I called the guix deploy function with `(guix-main "/mnt/bcachefs/srv/git/custom-guix-repo/scripts/guix" "deploy" "/home/mzan/lavoro/admin/guix/buildbart/deploy.scm")`
- I obtain the error message `ice-9/boot-9.scm:1685:16: In procedure raise-exception: In procedure port-column: Wrong type argument in position 1: #<closed: string 7efc1922e1c0>`
- I can play with the Guile debug shell, for inspecting better the source of the error
- I'm not an expert but the CL SBCL debug session seems a lot more interactive, and I can explore better. In Guile it is a lot less fun.

Sadly the obtained error is different from the error executing on the command line, using `./pre-inst-env`, and it starts to becoming frustrating

### Debugging using test code

I created simplified version of the code, for isolating the error, and I called from Geiser, using 

```
(guix-main "/mnt/bcachefs/srv/git/custom-guix-repo/scripts/guix" "deploy" "/home/mzan/lavoro/admin/guix/buildbart/deploy.scm")
```

 So instead of an interactive process, like in CL, an iterative one:

- save the code;
- simplify the code;
- create test code;
- print some results;
- isolate the error;
- backport the fix to the real saved code;

This process is far from ideal. 

### Debugging of code to execute as root

The Guile code used in the `initrd` phase can call protected files, e.g. for reading the bcachefs super-block. So I cannot execute it inside a Geiser process.

I created this file, containing code to test. It must be safe code, because it will run as root:

```scheme
; t.scm

(use-modules (gnu build file-systems))

(canonicalize-device-spec "/dev/sda:/dev/sda1:/dev/sdb:/dev/sdc")
```

and I call it with

```
$ ./pre-inst-env sudo -E guix repl t.scm
```

obtaining these debug mesages

```
specs: ("/dev/sda" "/dev/sda1" "/dev/sdb" "/dev/sdc")

 "/dev/sda" #f #f
 "/dev/sda1" #f #vu8(218 217 209 178 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 193 184 1 212 171 134 78 98 176 210 248 239 125 66 72 121 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 95 66 72 82 102 83 95 77 165 226 1 0 0 0 0 0 0 192 28 33 35 0 0 0 0 64 135 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 160 56 58 0 0 0 0 208 76 18 35 0 0 0 6 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 16 0 0 0 64 0 0 0 64 0 0 0 16 0 0 129 0 0 0 177 220 1 0 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0
[...]
 0 0 0 0 0 0 0 0 0 0 0 0 0 0)

 "/dev/sdb" #f #f
 "/dev/sdc" #f #f
 valid-specs: ()
Backtrace:
           3 (primitive-load "/mnt/bcachefs/home/mzan/lavoro/admin/c…")
In ice-9/eval.scm:
    619:8  2 (_ #(#(#(#(#<directory (gnu build file-syst…> …) …) …) …))
In ice-9/boot-9.scm:
   2007:7  1 (error _ . _)
  1685:16  0 (raise-exception _ #:continuable? _)

ice-9/boot-9.scm:1685:16: In procedure raise-exception:
failed to resolve multi-device  "/dev/sda:/dev/sda1:/dev/sdb:/dev/sdc"
```

This message contains also debug info I manually generated using `(format #t ...)` code.



