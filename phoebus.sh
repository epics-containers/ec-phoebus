#!/bin/bash

# A launcher for the phoebus container that allows X11 forwarding

thisdir=$(realpath $(dirname ${0}))

# assume podman for now - change this to docker if needed
docker=podman
args="--security-opt=label=type:container_runtime_t"

XSOCK=/tmp/.X11-unix # X11 socket (but we mount the whole of tmp)
XAUTH=/tmp/.container.xauth.$USER
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
chmod 777 $XAUTH

x11="
-e DISPLAY
-v $XAUTH:$XAUTH
-e XAUTHORITY=$XAUTH
--net host
"

args=${args}"
-it
--pull newer
"

export MYHOME=/home/${USER}
# mount in your own home dir in same folder for access to external files
mounts="
-v=/tmp:/tmp
-v=${MYHOME}/.ssh:/root/.ssh
-v=${MYHOME}:${MYHOME}
-v=${thisdir}:/workspace
"

# use the host's time zone so that times (e.g. data browser plot axes) are
# local rather than the container's default of UTC. Java reads the TZ
# environment variable first and resolves zone names from its own tz database.
# (Bind-mounting /etc/localtime does not help Java: in the image it is a
# symlink, so the mount lands on its target and the JDK still reads Etc/UTC.)
host_tz=${TZ:-$(timedatectl show -p Timezone --value 2>/dev/null)}
if [[ -z ${host_tz} && -L /etc/localtime ]]; then
    host_tz=$(readlink -f /etc/localtime | sed -n 's|.*/zoneinfo/||p')
fi
if [[ -z ${host_tz} && -r /etc/timezone ]]; then
    # the zone name Debian/Ubuntu keep alongside /etc/localtime
    host_tz=$(head -n 1 /etc/timezone)
fi
if [[ -n ${host_tz} ]]; then
    args+="
-e TZ=${host_tz}
"
else
    # no zone name found. (podman --tz=local is no help: like a bind mount it
    # replaces the file behind the image's /etc/localtime symlink, and the JDK
    # takes the zone from the symlink's name, so it would still show UTC.)
    echo "WARNING: could not determine the host time zone, times will be UTC." \
        "Run with e.g. TZ=Europe/London bash ${0}" >&2
fi

# if there is a settings.ini next to this script mount it over the default one
if [[ -f ${thisdir}/settings.ini ]]; then
    mounts+="-v=${thisdir}/settings.ini:/settings/settings.ini"
fi

set -x
$docker run ${mounts} ${args} ${x11} \
  ghcr.io/epics-containers/ec-phoebus:latest \
  -settings /settings/settings.ini -server 4918 -add-modules=ALL-SYSTEM "${@}"
