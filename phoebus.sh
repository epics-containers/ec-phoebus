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
# environment variable first and resolves zone names from its own tz database,
# so this works without tzdata in the image. Also mount /etc/localtime for
# anything else in the container that reads it.
host_tz=${TZ:-$(timedatectl show -p Timezone --value 2>/dev/null)}
if [[ -z ${host_tz} ]]; then
    if [[ -L /etc/localtime ]]; then
        host_tz=$(readlink -f /etc/localtime | sed -n 's|.*/zoneinfo/||p')
    elif [[ -r /etc/timezone ]]; then
        # /etc/localtime is a plain copy: use the zone name Debian/Ubuntu keep here
        host_tz=$(head -n 1 /etc/timezone)
    fi
fi
if [[ -n ${host_tz} ]]; then
    args+="
-e TZ=${host_tz}
"
fi
if [[ -e /etc/localtime ]]; then
    mounts+="
-v=/etc/localtime:/etc/localtime:ro
"
fi

# if there is a settings.ini next to this script mount it over the default one
if [[ -f ${thisdir}/settings.ini ]]; then
    mounts+="-v=${thisdir}/settings.ini:/settings/settings.ini"
fi

set -x
$docker run ${mounts} ${args} ${x11} \
  ghcr.io/epics-containers/ec-phoebus:latest \
  -settings /settings/settings.ini -server 4918 -add-modules=ALL-SYSTEM "${@}"
