FROM tomcat:9-jre8

ENV PINPOINT_VERSION=1.5.2
ENV PINPOINT_HOME=/opt/pinpoint-${PINPOINT_VERSION}
ENV PINPOINT_CONF_DIR=${PINPOINT_HOME}/conf

RUN apt-get update \
        && apt-get -y install wget 

# Download and extract collector and web
RUN set -u \
        && mkdir -p ${PINPOINT_HOME}/collector ${PINPOINT_HOME}/web ${PINPOINT_CONF_DIR} \
        && cd ${PINPOINT_HOME}/collector \
        && wget https://github.com/naver/pinpoint/releases/download/${PINPOINT_VERSION}/pinpoint-collector-${PINPOINT_VERSION}.war \
        && unzip pinpoint-collector-${PINPOINT_VERSION}.war \
        && cd ${PINPOINT_HOME}/web \
        && wget https://github.com/naver/pinpoint/releases/download/${PINPOINT_VERSION}/pinpoint-web-${PINPOINT_VERSION}.war \
        && unzip pinpoint-web-${PINPOINT_VERSION}.war 

COPY start /opt/start
COPY tools.sh /opt/tools.sh
COPY conf ${PINPOINT_CONF_DIR}

WORKDIR ${PINPOINT_HOME}
#ENTRYPOINT ["/opt/start"]
CMD ["/opt/start"]

