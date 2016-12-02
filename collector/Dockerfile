FROM tomcat:8-jre8
MAINTAINER Jongseok Choi <cjongseok@gmail.com>

ENV PINPOINT_VERSION 1.6.0-RC2
ENV PINPOINT_HOME /opt/pinpoint-${PINPOINT_VERSION}
ENV WAR_BALL pinpoint-collector-${PINPOINT_VERSION}.war

ENV CATALINA_ROOT_APP ${CATALINA_HOME}/webapps/ROOT

RUN set -e \
        && set -x \
        && apt-get install -y wget \
        && mkdir -p ${PINPOINT_HOME} \
        && cd ${PINPOINT_HOME} \
        && wget https://github.com/naver/pinpoint/releases/download/${PINPOINT_VERSION}/${WAR_BALL}

COPY scripts ${PINPOINT_HOME}/scripts

RUN set -e \
        && set -x \
        && rm -rf ${CATALINA_ROOT_APP} \
        && mkdir -p ${CATALINA_ROOT_APP} \
        && cd ${CATALINA_ROOT_APP} \
        && unzip -q ${PINPOINT_HOME}/${WAR_BALL}

WORKDIR ${PINPOINT_HOME}

CMD ["scripts/start-collector.sh"]
