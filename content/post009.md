Title: How to maintain a private Guix fork
Date: 2024-10-14
Category: Guix
tags: guix

Scope:

- customize default #guix channel;
- use it in the working environment/system (i.e. "eating your own dog food");
- send patches to #guix upstream;
- wait patches are merged;

## Preparation

I installed #guix from source code, as described [here](https://guix.gnu.org/manual/devel/en/html_node/Contributing.html).

I'm using [Stacked-Git](https://stacked-git.github.io/) for managing patches. 

When I need to extend #guix, I search first in the [contributor page](https://issues.guix.gnu.org/) if there is some open pull request to use as starting point. There can be also Guix channels in external repositories.

I create a patch, using Stacked-Git.

I test the build of packages, using the instructions in Guix manual.

## Installing a system

Some packages like the window-manager must be tested on a live system. Better if it is the working environment. I use

```
sudo -E ./pre-inst-env guix system reconfigure /home/mzan/lavoro/admin/guix/think/config-nonguix.scm
```

In particular without `sudo -E`, it will not work correctly.

## The build/reconfigure workflow

I'm using [just](https://github.com/casey/just) for defining simple scripts, and [nushell](https://www.nushell.sh/) as scripting language. 

These are the scripts in `justfile` for system build and upgrade:

```
# Import new changes.
pull:
    #!/usr/bin/env nu
    guix pull
    cd custom-guix-repo
    stg branch | into string | str trim | $in == "master"
    stg pull
    cd ../nonguix-repo
    git pull

# Fix permissions, that can be corrupted during sudo system reconfigure
fix-permissions:
    sudo chown -R mzan:users custom-guix-repo
    sudo chown -R mzan:users /home/mzan/.cache/guix
    sudo chown -R mzan:users /home/mzan/.cache/guile

# Recompile from scratch repo files. Slow, but sometime it is required.
repo-bootstrap: fix-permissions
    sudo rm -r -f /home/mzan/.cache/guix
    sudo rm -r -f /home/mzan/.cache/guile
    cd custom-guix-repo && guix shell -D guix help2man git strace pkg-config bash --pure -- bash -c "./bootstrap && ./configure --localstatedir=/var && make clean && make"

# Update repo files. Faster than `repo-bootstrap`.
repo-make: fix-permissions
    cd custom-guix-repo && guix shell -D guix help2man git strace pkg-config bash --pure -- make

# Try to build a new version of the system, relaunching the task for 10 times in case of errors.
system-build10: fix-permissions
    #!/usr/bin/env nu
    cd custom-guix-repo
    stg branch | into string | str trim | $in == "master"
    for $it in [1 2 3 4 5 6 7 8 9 10] {
      try {
        print "###"
        print $"### Attempt ($it)"
        print "###"
        ./pre-inst-env guix system build /home/mzan/lavoro/admin/configs/config-think.scm --keep-going

        print "###"
        print $"### Success at pass ($it)"
        print "###"

        break
      }
      print "!!!"
      print $"!!! Failure at pass ($it). Wait 60sec and retry."
      print "!!!"

      sleep 60sec
    }

# Like 'system-build10' but using 2 jobs.
system-build10x2: fix-permissions
    #!/usr/bin/env nu
    cd custom-guix-repo
    stg branch | into string | str trim | $in == "master"
    for $it in [1 2 3 4 5 6 7 8 9 10] {
      try {
        print "###"
        print $"### Attempt ($it)"
        print "###"
        ./pre-inst-env guix system build --keep-going --max-jobs=2 /home/mzan/lavoro/admin/configs/config-think.scm
        print "###"
        print $"### Success at pass ($it)"
        print "###"

        break
      }
      print "!!!"
      print $"!!! Failure at pass ($it). Wait 60sec and retry."
      print "!!!"

      sleep 60sec
    }

# Like 'system-build10', but it works also if ci.gnu.guix.org is down.
system-build10-fallback: fix-permissions
    #!/usr/bin/env nu
    cd custom-guix-repo
    stg branch | into string | str trim | $in == "master"
    for $it in [1 2 3 4 5 6 7 8 9 10] {
      try {
        print "###"
        print $"### Attempt ($it)"
        print "###"
        ./pre-inst-env guix system build /home/mzan/lavoro/admin/configs/config-think.scm --keep-going --no-substitutes --substitute-urls="https://git.savannah.gnu.org/git/guix.git https://bordeaux.guix.gnu.org https://gitlab.com/nonguix/nonguix"

        print "###"
        print $"### Success at pass ($it)"
        print "###"

        break
      }
      print "!!!"
      print $"!!! Failure at pass ($it). Wait 60sec and retry."
      print "!!!"

      sleep 60sec
    }

# Build the system as normal user and then install it
system-reconfigure: system-build10
    #!/usr/bin/env nu
    cd custom-guix-repo
    stg branch | into string | str trim | $in == "master"
    sudo -E ./pre-inst-env guix system reconfigure /home/mzan/lavoro/admin/configs/config-think.scm --keep-going

# Like system-reconfigure but with fallback if CI server is down
system-reconfigure-no-ci: system-build10-fallback
    #!/usr/bin/env nu
    cd custom-guix-repo
    stg branch | into string | str trim | $in == "master"
    sudo -E ./pre-inst-env guix system reconfigure /home/mzan/lavoro/admin/configs/config-think.scm --keep-going --no-substitutes --substitute-urls="https://git.savannah.gnu.org/git/guix.git https://bordeaux.guix.gnu.org https://gitlab.com/nonguix/nonguix"

# Create a new patch in the 'custom-guix-repo'.
new-patch name:
    #!/usr/bin/env nu
    cd custom-guix-repo
    stg branch | into string | str trim | $in == "master"
    stg pull
    stg new {{name}}
    stg series

# Update the (many) packages of the hyprland project
refresh-hyprland:
    #!/usr/bin/env sh
    cd custom-guix-repo
    ./pre-inst-env guix refresh -u \
        hyprland aquamarine hyprcursor \
        hyprlang hyprutils hyprlock hypridle hyprpaper hyprpicker \
        hyprwayland-scanner wayland-protocols-next wayland \
        xdg-desktop-portal-hyprland
```

## Adding other channels

The additional channels defined in `.config/guix/channels.scm` and returned by `guix describe` are not loaded by `./pre-inst-env`. For adding them:

- clone the channel content
- make sure to pull updates when you pull the main guix channel
- modify `pre-inst-env` from something like `GUILE_LOAD_PATH="$abs_top_builddir:$abs_top_srcdir${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
e` to something like `GUILE_LOAD_PATH="/mnt/bcachefs/home/mzan/lavoro/admin/nonguix-repo:$abs_top_builddir:$abs_top_srcdir${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
e`
- make sure to apply again this modification, if you call `just repo-bootstrap`


