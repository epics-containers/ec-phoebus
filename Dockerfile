# Dockerfile for EPICS OPI PHoebus
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
ENV ROOT=/phoebus
ENV VERSION=4.7.2

RUN git clone https://github.com/ControlSystemStudio/phoebus.git \
    --branch=v${VERSION} ${ROOT}
WORKDIR ${ROOT}
RUN mvn -DskipTests clean install

ENTRYPOINT ["java", "-jar", "phoebus-product/target/product-${VERSION}.jar", \
    "-server", "4918", "--add-modules=ALL-SYSTEM"]
