# Dockerfile for EPICS OPI PHoebus

# NOTE: I had to build this image with --network host. Otherwise
# the maven downloads are very slow. I am of the opinion this is an MTU
# mismatch between docker and host networks (requires investigation)

##### shared environment stage #################################################
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&  apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
RUN apt-get install -y \
    openjdk-11-jdk \
    maven \
    openjfx \
    git

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

# get phoebus and dependencies
RUN git clone https://github.com/ControlSystemStudio/phoebus.git ${PHOEBUS_DIR} && \
    mvn clean verify -f dependencies/pom.xml \
    mvn clean install


RUN bash -c "ln -s phoebus-product/target/product-*-SNAPSHOT.jar product.jar"
ENTRYPOINT ["java", "-jar", "/phoebus/product.jar", "-server", "4918"]
