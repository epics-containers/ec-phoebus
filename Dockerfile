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
ENV VERSION=4.7.3

RUN git clone https://github.com/ControlSystemStudio/phoebus.git \
    --branch=v${VERSION} ${ROOT}
WORKDIR ${ROOT}

# CANNOT work out how to do this in a -settings settings.xml launch config - meh
RUN sed -i 's|colors_list=|colors_list=/settings/colors.list|' app/display/convert-edm/src/main/resources/edm_converter_preferences.properties

RUN mvn -DskipTests clean install

RUN ln -s phoebus-product/target/product-${VERSION}.jar phoebus.jar

COPY /settings /settings

ENTRYPOINT ["java", "-jar", "phoebus.jar",  "-settings=/settings/settings.ini", "-server", "4918", "--add-modules=ALL-SYSTEM"]
