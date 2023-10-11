# Dockerfile for EPICS OPI PHoebus

# NOTE: I had to build this image with --network host. Otherwise
# the maven downloads are very slow. I am of the opinion this is an MTU
# mismatch between docker and host networks (requires investigation)

##### shared environment stage #################################################
ARG REGISTRY=ghcr.io/epics-containers
ARG EPICS_VERSION=7.0.7ec2

FROM ${REGISTRY}/epics-base-linux-developer:${EPICS_VERSION} AS environment

# environment
ENV PHOEBUS_DIR=/phoebus
WORKDIR ${PHOEBUS_DIR}
ENV LANG=en_US.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV DEBIAN_FRONTEND=noninteractive

##### build stage ##############################################################

FROM environment AS developer

# install additional packages
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    default-jdk \
    libc-dev-bin \
    libopenjfx-jni \
    libopenjfx-java \
    locales \
    maven \
    openjfx \
    busybox-static \
    ssh \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# get phoebus and dependencies
RUN git clone https://github.com/ControlSystemStudio/phoebus.git ${PHOEBUS_DIR} && \
    mvn clean verify -f dependencies/pom.xml

# build and install phoebus
RUN locale-gen en_US.UTF-8 && \
    mvn clean install


RUN bash -c "ln -s phoebus-product/target/product-*-SNAPSHOT.jar product.jar"
ENTRYPOINT ["java", "-jar", "/phoebus/product.jar", "-server", "4918"]

# USER ${USERNAME}

##### runtime stage ############################################################

# FROM environment AS runtime

# TODO copy build output

USER ${USERNAME}