
#!/bin/bash

# A launcher for the phoebus container that allows X11 forwarding

thisdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

if [[ $(docker --version 2>/dev/null) == *Docker* ]]; then
    docker=docker
else
    docker=podman
    args="--security-opt=label=type:container_runtime_t"
fi

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
"

export MYHOME=/home/${USER}
mounts="
-v=/tmp:/tmp
-v=${MYHOME}/.ssh:/root/.ssh
"

set -x
$docker run ${mounts} ${args} ${x11} ghcr.io/epics-containers/ec-phoebus:latest
