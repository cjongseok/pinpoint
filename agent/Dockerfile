FROM cjongseok/oracle-jdk:1.8.0_77
MAINTAINER Jongseok Choi <cjongseok@gmail.com> 

ENV PINPOINT_VERSION 1.6.0-RC2
ENV PINPOINT_HOME /opt/pinpoint-${PINPOINT_VERSION}
ENV PINPOINT_AGENT_HOME ${PINPOINT_HOME}/agent
ENV PINPOINT_APP_HOME ${PINPOINT_HOME}/app
ENV TAR_BALL pinpoint-agent-${PINPOINT_VERSION}.tar.gz

ENV CATALINA_ROOT_APP ${CATALINA_HOME}/webapps/ROOT

RUN set -e \
        && set -x \
        && apt-get install -y wget \
        && mkdir -p ${PINPOINT_AGENT_HOME} \
        && cd ${PINPOINT_AGENT_HOME} \
        && wget https://github.com/naver/pinpoint/releases/download/${PINPOINT_VERSION}/${TAR_BALL} \
        && tar xzf ${TAR_BALL} \
        && rm ${TAR_BALL} 


#COPY ${WAR_BALL} ${PINPOINT_HOME}/${WAR_BALL}
COPY scripts ${PINPOINT_HOME}/scripts
#COPY start-collector.sh ${PINPOINT_HOME}/start-collector.sh

WORKDIR ${PINPOINT_HOME}

CMD ["scripts/run.sh"]
