# rbenv local path

This contains the local ruby install.

This is copied from the container image's `/opt/base-rbenv` path to reset it to
a known good copy. You can use the `cdo reset` command to restore this to the
container path. This is useful if you've recently upgraded the container or you
have an unstable local environment.
