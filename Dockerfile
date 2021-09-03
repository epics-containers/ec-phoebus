# EPICS Dockerfile for Asyn and other fundamental support modules
ARG REGISTRY=ghcr.io/epics-containers
ARG EPICS_VERSION=7.0.5r3.0

# important: I had to build this image with --network host. Otherwise
# the maven downloads are very slow. I am of the opinion this is an MTU
# mismatch between docker and host networks (requires investigation)

##### build stage ##############################################################

FROM ${REGISTRY}/epics-base:${EPICS_VERSION} AS developer

# install additional packages
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    default-jdk \
    libc-dev-bin \
    locales \
    maven \
    python3-pip \
    python3.8-minimal \
    busybox-static \
    ssh \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# give user sudo rights while developing this image
RUN usermod -aG sudo ${USERNAME} && \
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME}

WORKDIR ${EPICS_ROOT}/tools

ENV PHOEBUS_DIR=${EPICS_ROOT}/tools/phoebus

# get phoebus and dependencies
RUN git clone https://github.com/ControlSystemStudio/phoebus.git && \
    cd ${PHOEBUS_DIR} && \
    mvn clean verify -f dependencies/pom.xml

ENV LANG=en_US.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# build and install phoebus
RUN locale-gen en_US.UTF-8 && \
    cd ${PHOEBUS_DIR} && \
    mvn clean install

USER ${USERNAME}
