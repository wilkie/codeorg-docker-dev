# nvm local path

This contains the local environment for the container's nvm. This is originally
installed via the container's `/opt/base-nvm` path. The `cdo reset` command will
restore it to the container's prebuilt path. This is useful if the container has
been updated or your local environment is broken in some way.
