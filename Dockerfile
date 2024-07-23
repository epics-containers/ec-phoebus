# Dockerfile for EPICS OPI PHoebus
FROM ubuntu:20.04 as common

    ENV DEBIAN_FRONTEND=noninteractive

    RUN apt-get update &&  apt-get install -y locales
    RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
        dpkg-reconfigure --frontend=noninteractive locales && \
        update-locale LANG=en_US.UTF-8

    ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
    ENV LANG en_US.UTF-8
    ENV ROOT=/phoebus
    ENV VERSION=4.7.3
    ENV TARGET=phoebus-product/target
    WORKDIR ${ROOT}

FROM common as build

    RUN apt-get install -y \
        openjdk-11-jdk \
        maven \
        openjfx \
        git

    RUN git clone https://github.com/ControlSystemStudio/phoebus.git \
        --branch=v${VERSION} ${ROOT}

    # CANNOT work out how to do this in a -settings settings.xml launch config - meh
    RUN sed -i 's|colors_list=|colors_list=/settings/colors.list|' app/display/convert-edm/src/main/resources/edm_converter_preferences.properties

    RUN mvn -DskipTests clean install

    RUN ln -s ${TARGET}/product-${VERSION}.jar phoebus.jar

    COPY /settings /settings

FROM common as runtime

    RUN apt-get install -y \
        openjdk-11-jre \
        openjfx

    COPY --from=build ${TARGET}/product-${VERSION}.jar ${TARGET}/phoebus.jar
    COPY --from=build ${TARGET}/lib ${ROOT}/${TARGET}/lib
    COPY --from=build /settings /settings
    RUN ln -s ${TARGET}/phoebus.jar phoebus.jar

    ENTRYPOINT ["java", "-jar", "phoebus.jar",  "-settings=/settings/settings.ini", "-server", "4918", "--add-modules=ALL-SYSTEM"]