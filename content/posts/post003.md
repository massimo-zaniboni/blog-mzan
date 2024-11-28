---
title: Creating a Guix VM under QEMU
date: 2024-11-06
tags: [guix]
---

## Requirements:

The  VM starts in [Virtual-Machine-Manager](https://virt-manager.org/), and it is administered using [`guix deploy`](https://guix.gnu.org/manual/en/html_node/Invoking-guix-deploy.html).

## Overview

- create a qcow2 system image
- resize the partition
- expand the file-system
- install on virtual-machine-manager 

## Container definition

I created a template like this

```scheme
(use-modules
  (gnu )
  (gnu packages aspell)
  (gnu packages attr)
  (gnu packages ci)
  (gnu packages cups)
  (gnu packages vim)
  (gnu packages version-control)
  (gnu packages file-systems)
  (gnu packages fontutils)
  (gnu packages image)
  (gnu packages package-management)
  (gnu packages graphviz)
  (gnu packages rust-apps)
  (gnu packages fonts)
  (gnu packages shellutils)
  (gnu packages code)
  (gnu packages patchutils)
  (gnu packages documentation)
  (gnu packages screen)
  (gnu packages admin)
  (gnu packages plan9)
  (gnu packages password-utils)
  (gnu packages disk)
  (gnu packages networking)
  (gnu packages linux)
  (gnu packages rsync)
  (gnu packages sync)
  (gnu packages compression)
  (gnu packages backup)
  (gnu packages shells)
  (gnu packages tcl)
  (gnu packages flashing-tools)
  (gnu packages toys)
  (gnu packages messaging)
  (gnu packages syndication)
  (gnu packages sqlite)
  (gnu packages virtualization)
  (gnu packages cryptsetup)
  (gnu packages samba)
  (gnu system)
  (ice-9 textual-ports)
  (gnu home)
  (gnu home services)
  (gnu home services shells)
  (gnu packages haskell-apps)
  (gnu packages haskell-xyz)
  (gnu packages commencement)
  (gnu services shepherd)
  (gnu system locale)
  (gnu packages unicode)
  (gnu packages terminals)
  (gnu packages version-control)
  (guix channels)
  (srfi srfi-1))

(use-service-modules networking ssh)

(operating-system
  (locale "en_US.utf8")
  (timezone "Europe/Rome")
  (keyboard-layout (keyboard-layout "it" "winkeys"))
  (host-name "template")

  (file-systems (cons (file-system
                        (device (file-system-label "does-not-matter"))
                        (mount-point "/")
                        (type "ext4"))
                      %base-file-systems))

  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (targets '("/dev/sdX"))))

  (users (cons* (user-account
                  (name "mzan")
                  (comment "Massimo Zaniboni")
                  (group "users")
                  (home-directory "/home/mzan")
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))

                (user-account
                  (name "deploy")
                  (comment "Guix deploy user")
                  (group "users")
                  (home-directory "/home/deploy")
                  (supplementary-groups '("wheel" "netdev")))
                %base-user-accounts))

   (sudoers-file
      (plain-file "sudoers"
        (string-append (plain-file-content %sudoers-specification)
                           "deploy ALL = NOPASSWD: ALL
")))

  (packages
   (cons*
      vim htop git rsync
      the-silver-searcher
      ripgrep fd direnv shellcheck
      screen

      bcachefs-tools
      cryptsetup
      f2fs-tools
      cifs-utils
      wipe
      parted gpart
      attr ; extended file attributes
      rsync rclone

      nushell
      just

      util-linux

      %base-packages))

  (services
   (cons*
     (service dhcp-client-service-type)
     (service openssh-service-type)

     (modify-services %base-services
       (guix-service-type config => (guix-configuration
         (inherit config)
         (authorized-keys
           (cons* (local-file "/home/mzan/lavoro/admin/configs/files/keys/master.signing-key.pub")
                  %default-authorized-guix-keys))))))))
```
## Creation of the qcow2 image

I run inside my custom Guix repository:

```
/pre-inst-env guix system image --image-type=qcow2 /home/mzan/lavoro/admin/configs/container-template.scm
```

At the end, it is returned the file name of the image. I imported it, into my directory containing other virtual-machines:

```
$ sudo cp /gnu/store/mpjmjn16l2z3vkcpalwx980p4jna4qp0-image.qcow2 /var/opt/virtual-machines-to-test/virt-manager/guix01.qcow2

$ sudo chmod +w /var/opt/virtual-machines-to-test/virt-manager/guix01.qcow2

$ sudo chown mzan:users /var/opt/virtual-machines-to-test/virt-manager/guix01.qcow2
```

## Resize of the image 

Guix creates a qcow2 file without space for additional packages and data. I will increase its logical size. The physical size will increase only on real demand.

```
$ qemu-img info guix01.qcow2

image: guix01.qcow2
file format: qcow2
virtual size: 2.36 GiB (2535514112 bytes)
disk size: 721 MiB
cluster_size: 65536
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false
Child node '/file':
    filename: guix01.qcow2
    protocol type: file
    file length: 726 MiB (760793088 bytes)
    disk size: 721 MiB 

$ qemu-img resize guix01.qcow2 +200G
Image resized.
```

## Initialize the VM 

I import the image into [Virtual-Machine-Manager](https://virt-manager.org/). 

I launch it. I enter as root and I set a password using `passwd`, `passwd mzan`, and `passwd deploy`, becuase initially there are no passwords.

I check the internal *ip address* with `ip a`, and I set a ssh with a private, i.e. something like 

```
$ cd ~/.ssh
$ ssh-copy-id -i guix-deploy.pub mzan@192.168.100.155
$ ssh-copy-id -i guix-deploy.pub deploy@192.168.100.155
```

## Expand the file-system

The qcow2 image was resized, but the partition and file-system no. I execute something like this:

```
$ ssh mzan@192.168.100.155

$ sudo lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 202.4G  0 disk
├─sda1   8:1    0    40M  0 part
└─sda2   8:2    0   2.3G  0 part /gnu/store
                                 /

$ sudo cfdisk /dev/sda
# I resize the partition sda2

$ sudo resize2fs /dev/sda2

$ df -hT
Filesystem     Type      Size  Used Avail Use% Mounted on
none           devtmpfs  1.5G     0  1.5G   0% /dev
/dev/sda2      ext4      200G  2.1G  190G   2% /
tmpfs          tmpfs     1.5G     0  1.5G   0% /dev/shm
```

## Administer using "guix deploy"

I must refine the template definition. 

First I will obtain the uuid of the partitions. Inside the template VM:

```
$ sudo blkid 
/dev/sda2: LABEL="Guix_image" UUID="38af4c98-04f8-c549-ad36-132e38af4c98" BLOCK_SIZE="4096" TYPE="ext4"
/dev/sda1: SEC_TYPE="msdos" LABEL_FATBOOT="GNU-ESP" LABEL="GNU-ESP" UUID="CE91-D34B" BLOCK_SIZE="512" TYPE="vfat"
```

In my local admin directory I prepare a configuration file: according the guidelines of [`guix deploy` format](https://guix.gnu.org/manual/en/html_node/Invoking-guix-deploy.html).

```scheme
; deploy-local-vms.scm
 
(use-modules
  (gnu)
  (gnu packages admin)
  (gnu packages aspell)
  (gnu packages attr)
  (gnu packages ci)
  (gnu packages cups)
  (gnu packages vim)
  (gnu packages version-control)
  (gnu packages file-systems)
  (gnu packages fontutils)
  (gnu packages image)
  (gnu packages package-management)
  (gnu packages graphviz)
  (gnu packages rust-apps)
  (gnu packages fonts)
  (gnu packages shellutils)
  (gnu packages code)
  (gnu packages patchutils)
  (gnu packages documentation)
  (gnu packages screen)
  (gnu packages admin)
  (gnu packages plan9)
  (gnu packages password-utils)
  (gnu packages disk)
  (gnu packages networking)
  (gnu packages linux)
  (gnu packages rsync)
  (gnu packages sync)
  (gnu packages compression)
  (gnu packages backup)
  (gnu packages shells)
  (gnu packages tcl)
  (gnu packages flashing-tools)
  (gnu packages toys)
  (gnu packages messaging)
  (gnu packages syndication)
  (gnu packages sqlite)
  (gnu packages virtualization)
  (gnu packages cryptsetup)
  (gnu packages samba)
  (gnu system)
  (ice-9 textual-ports)
  (gnu home)
  (gnu home services)
  (gnu home services shells)
  (gnu packages haskell-apps)
  (gnu packages haskell-xyz)
  (gnu packages commencement)
  (gnu services shepherd)
  (gnu system locale)
  (gnu packages unicode)
  (gnu packages terminals)
  (gnu packages version-control)
  (guix channels)
  (srfi srfi-1)
  (gnu system)
  (ice-9 textual-ports))

(use-service-modules cups desktop networking ssh xorg)

(define %guix-server
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "it" "winkeys"))
    (host-name "guix01")

    (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets (list "/dev/sda"))))

    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid "38af4c98-04f8-c549-ad36-132e38af4c98"))
                           (type "ext4"))
                         %base-file-systems))

    (users (cons*
            (user-account
               (name "mzan")
               (comment "Massimo")
               (group "users")
               (home-directory "/home/mzan")
               (supplementary-groups '("wheel" "netdev" "audio" "video")))
            (user-account
              (name "deploy")
              (comment "Guix deploy user")
              (group "users")
              (home-directory "/home/deploy")
              (supplementary-groups '("wheel" "netdev")))
            %base-user-accounts))

    (sudoers-file
      (plain-file "sudoers"
        (string-append (plain-file-content %sudoers-specification)
                           "deploy ALL = NOPASSWD: ALL
")))

    (packages
     (cons*
      vim htop git rsync
      the-silver-searcher
      ripgrep fd direnv shellcheck
      screen

      bcachefs-tools
      cryptsetup
      f2fs-tools
      cifs-utils
      wipe
      parted gpart
      attr ; extended file attributes
      rsync rclone

      nushell
      just

      util-linux
      %base-packages))

    (services
      (cons*
        (service openssh-service-type)
        (service dhcp-client-service-type)

        (modify-services %base-services
          (guix-service-type config => (guix-configuration
            (inherit config)
            (authorized-keys
              (cons* (local-file "/home/mzan/lavoro/admin/configs/files/keys/master.signing-key.pub")
                      %default-authorized-guix-keys)))))))))

(list (machine
        (operating-system %guix-server)
        (environment managed-host-environment-type)
        (configuration
          (machine-ssh-configuration
            (host-name "192.168.100.155")
            (system "x86_64-linux")
            (user "deploy")
            (identity "/home/mzan/.ssh/guix-deploy")))))
```

In this file I set:

- the correct uuid to mount;
- the device where installing grub;
- the ip, user and key to use for accessing it during deploy;
- the masker-key of the host, so the host can send closures to the guest store;

I install the VM, from my private repository:

```
$ ./pre-inst-env guix deploy /home/mzan/lavoro/admin/configs/deploy-local-vms.scm
```

Finally I reboot the VM.

