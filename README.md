# Repo structure

We take `docker_test` to be the parent repo, where there can be child repos like `s2i-python-container`. A child repo exists, if it is from an existing public repo that we have forked.

We do not use `git submodule`. We are not yet clear how to apply a `git submodule` workflow. So, we will stick to the simpler `git clone` workflow, where each child repo tracking its upstream branch for changes.
- The down-side of this, is that there will be 2 copies of the child repo. First, in the child repo's own remote. Second, in this parent repo's remote.
- The up-side is that we can simply clone this remote, i.e. the parent remote, and get all the work that has been done--even if the child repo were to be deleted later--which may be the case because we may not wish to maintain the forked copies in our remote.

# s2i-python-container
The objective is to test how setting up a Python virtualenv, as part of the image build, can be said to be henceforth the Python env used for all Python scripts. This may not seem apparent, because simply setting up a Python virtualenv gives no such guarantee.

To test this out, we **change the original Dockerfile in `s2-ipython-container/3.8`**, where the original Dockerfile had set up a Python virtualenv.

`/opt/app-root/etc/scl_enable` is a shellscript that contains the line that is responsible for activating the virtualenv when starting bash. This shellscript runs on every command issued from a shell. This begs the question: how did this script come to exist, and what triggers the scl_enable shellscript?

## How did this scl_enable script come to exist?

It is copied as part of the build, with the command `COPY ./root/`. So, it isn't created when running `scl_source enable rh-python38` or `scl enable rh-python38`.

## What triggers this scl_enable script?

Initially, we thought this ought to be somewhere in the bashprofile. But this does not show up when grep-ing the `/etc`. It turns out that a combination of 3 env variables set as part of the container image, ensures that the Python virtualenv is run on every command issued from the shell. The existence of these variables is apparent by running `docker inspect <container id>`.

First, `BASH_ENV=/opt/app-root/etc/scl_enable`. This handles all `docker run <command>` that rides on the entrypoint. The non-interactive bash shell is used, as part of the entrypoint, i.e. `container-entrypoint`. Note the shebang on the entrypoint script.
```
#!/bin/bash
exec "$@"
```

Second, `ENV=/opt/app-root/etc/scl_enable`. This is for interactive non-bash shell scripts.

Third, `PROMPT_COMMAND=. /opt/app-root/etc/scl_enable`. This is for interactive bash logins. The current commit shows another change to the original s2i repo, where we **set `PROMPT_COMMAND=""`, which leads to scl_enable script *not* running when starting interactive bash sessions using `docker exec -it ... bash`.

# bash-env
The objective is to demonstrate the workings of profile scripts on the shell used by an entrypoint.

To set this up, the Dockerfile first installs bash in the alpine image. Then, we copy the entrypoint script (i.e. `entrypoint.sh`), as well as the profile scripts `set_bash_env` and `set_sh_env` into the container. Within each of these scripts, we echo a line so that we know when they have been triggered.

Both `set_bash_env` and `entrypoint.sh` are triggered when running `docker run ... <cmd>` *in that order*. This is because `entrypoint.sh` is run in a non-interactive bash shell (defined by the shebang). If `entrypoint.sh` uses a non-bash shell, `set_bash_env` will *not* run.

By comparison, `docker exec -it <container id> bash` will *not* run `set_bash_env` nor `entrypoint.sh`. Here, bash is started interactively. But if we run a command within bash, i.e. `docker exec -it <container id> bash '<insert command>'`, then this is a non-interactive bash shell and `set_bash_env` runs.