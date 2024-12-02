---
title: How to run a Docker service in Guix
date: 2024-12-02
tags: [guix]
---

## Scenario

I need a service like *Writefreely*, which is lacking a Guix package definition. I have no time or skill to port it to Guix.

As temporarly workaround, I can use Docker:  install *Writefreely* inside a Docker container; declare it using a normal (i.e. declarative) Guix system definition; export it to the web, using the *Nginx* proxy-service on the Guix host.

Doing so: I can reuse services defined in Docker but not yet in Guix; I have a good-enough declarative specification of the host.

## Preparing the host for supporting Docker

I prepare a file like this:

```scheme
; host.scm

(use-modules
  (guix)
  (gnu)
  (gnu packages admin)
  (gnu packages attr)
  (gnu packages ci)
  (gnu packages docker)
  (gnu packages vim)
  (gnu packages version-control)
  (gnu packages file-systems)
  (gnu packages image)
  (gnu packages package-management)
  (gnu packages screen)
  (gnu packages admin)
  (gnu packages password-utils)
  (gnu packages disk)
  (gnu packages networking)
  (gnu packages linux)
  (gnu packages rsync)
  (gnu packages sync)
  (gnu packages compression)
  (gnu packages backup)
  (gnu packages shells)
  (gnu packages sqlite)
  (gnu packages virtualization)
  (gnu system)
  (ice-9 textual-ports)
  (gnu packages commencement)
  (gnu services shepherd)
  (gnu system locale)
  (gnu packages unicode)
  (gnu packages terminals)
  (gnu packages version-control)
  (gnu packages web)
  (gnu packages web-browsers)
  (guix channels)
  (srfi srfi-1)
  (gnu system)
  (ice-9 textual-ports))

(use-service-modules certbot
                     dbus desktop docker
                     mcron
                     networking ssh web xorg)

(define %nginx-deploy-hook
  (program-file
   "certbot-deploy-hook.scm"
   (with-imported-modules
    '((gnu services herd))
    #~(begin
        (use-modules (gnu services herd))
        (with-shepherd-action 'nginx ('reload) result result)))))

(define (cert-path host file)
  (format #f "/etc/letsencrypt/live/~a/~a.pem" host (symbol->string file)))

(operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "it" "winkeys"))
    (host-name "dobbkmelody2")

    ; ...
    (users (cons*
            (user-account
               (name "mzan")
               (comment "Massimo")
               (group "users")
               (home-directory "/home/mzan")
               (supplementary-groups '("wheel" "netdev" "audio" "video")))
            %base-user-accounts))

    (packages
     (cons*
      vim htop git rsync ripgrep
      util-linux
      just

      docker-cli

      %base-packages))

    (services
      (cons*
        (service dhcp-client-service-type)

        (service dbus-root-service-type)
        (service elogind-service-type)
        (service containerd-service-type)
        (service docker-service-type)

        (service certbot-service-type
         (certbot-configuration
          (email "mzan@dokmelody.org")
          (certificates
           (list
            (certificate-configuration
             (domains (list "dokmelody.org"
                            "www.dokmelody.org"
                            "blog.dokmelody.org"))
             (deploy-hook %nginx-deploy-hook))))))

        (service nginx-service-type))))
```

I install it using 

```
guix system reconfigure host.scm
```

Only after this, we have defined the `docker` user. TODO probably this is a bug of Guix. 

We will add the `docker` user, in this way:

```scheme
    (users (cons*
            (user-account
               (name "mzan")
               (comment "Massimo")
               (group "users")
               (home-directory "/home/mzan")
               (supplementary-groups '("wheel" "netdev" "audio" "video" "docker" )))
            %base-user-accounts))
```

```
guix system reconfigure host.scm
```

## Installing the Writefreely Docker image

I define something like this, inside the directory  `/home/mzan/docker-images/writefreely-debian`: 

```
; Dockerfile
FROM debian:latest AS writefreely-debian

RUN apt-get update

RUN apt-get install -y \
  make \
  git \
  sqlite3 libsqlite3-dev \
  bash curl coreutils util-linux

COPY initial-data/ /tmp/initial-data

COPY writefreely_0.15.1_linux_amd64.tar.gz /bin.tar.gz
RUN cd / && rm -r -f writefreely && \
    tar xfz bin.tar.gz && \
    rm -f writefreely*.tar.gz

VOLUME /writefreely-data
# NOTE: this name must be unique for all containers

COPY run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /
CMD ["/run.sh"]

```

```
; initial-data/config.ini

[app]
default_visibility = public
federation = true
host = http://blog2.dokmelody.org
landing = /read
local_timeline = true
min_username_len = 1
open_registration = false
private = false
public_stats = true
single_user = false
site_name = Dokmelody Blog
theme = write

[database]
database = blog_dokmelody_org
filename = /writefreely-data/writefreely.db
type = sqlite3

[server]
autocert = true
bind = localhost
gopher_port = 0
keys_parent_dir = /writefreely-data
pages_parent_dir = /writefreely
port = 8060
static_parent_dir = /writefreely
templates_parent_dir = /writefreely
```

```
; run.sh

#!/usr/bin/env sh

# Check if the volume is empty
if [ -z "$(ls -A /writefreely-data)" ]; then
    echo "Initializing volume..."
    cp -r /tmp/initial-data/. /writefreely-data/
fi

cd /writefreely && ./writefreely -c /writefreely-data/config.ini
```

I put into `initial-data` also the `keys` and the `writefreely.db` of a previous instance. So, only during the first installation, it will start-s with the old data.

I initialize the image with 

```
  docker build -t writefreely-debian .
```

I initialize the data directories with

```
sudo mkdir -p /var/lib/opt/writefreely-data
sudo chown -R :docker /var/lib/opt/
```

## Declaration of the container 

I add this to `host.scm`

```
        (service oci-container-service-type
         (list
          (oci-container-configuration
           (image "writefreely-debian")
           (network "host")
           (ports (list '("8060" . "8060")))
           (volumes '("/var/lib/opt/writefreely-data:/writefreely-data")))))
```

NOTE:

- the service is visible on port 8060;
- the service will write on the `/var/lib/opt/writefreely-data` directory of the  *target-host*;

I connect now the `8060` port to Nginx:

```
        (simple-service
           'writefreely
           nginx-service-type
           (list
            (nginx-server-configuration
                      (listen '("443 ssl http2"
                                "[::]:443 ssl http2"))
                      (server-name '("blog.dokmelody.org"))
                      (ssl-certificate
                        (cert-path "dokmelody.org" 'fullchain))
                      (ssl-certificate-key
                        (cert-path "dokmelody.org" 'privkey))
                      (raw-content '("
    gzip on;
    gzip_types
      application/javascript
      application/x-javascript
      application/json
      application/rss+xml
      application/xml
      image/svg+xml
      image/x-icon
      application/vnd.ms-fontobject
      application/font-sfnt
      text/css
      text/plain;
    gzip_min_length 256;
    gzip_comp_level 5;
    gzip_http_version 1.1;
    gzip_vary on;

    location ~ ^/.well-known/(webfinger|nodeinfo|host-meta) {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_pass http://127.0.0.1:8060;
        proxy_redirect off;
    }

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_pass http://127.0.0.1:8060;
        proxy_redirect off;
    }
")))))
```

```
guix system reconfigure host.scm
```

Up to date, it is necessary to restart Nginx explicitely, for recognizing the new settings

```
sudo herd restart nginx
sudo renew-certbot-certificates
sudo herd restart nginx
```

TODO up to date, first the certificate must be created, then Nginx restarted. So the real commands are differents. I will document them in anothe post...

## Possible improvements 

- initialize the Docker image inside the `host.scm` file;
- send patches to Guix, for initializing the Nginx certificates and Docker user, without following an "imperative" sequence of operations;
