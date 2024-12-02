---
title: Notes about Guix Deploy 
date: 2024-12-01
tags: [guix]
draft: true
---

## The big picture

Guix build phases add files to the *store*. The *store* is mainly built locally, and then it is sent to the remote host, using `guix deploy`.


