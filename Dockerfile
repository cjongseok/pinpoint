FROM tomcat:9-jre8

ENV PINPOINT_VERSION=1.5.2
ENV PINPOINT_HOME=/opt/pinpoint-${PINPOINT_VERSION}
ENV PINPOINT_CONF_DIR=${PINPOINT_HOME}/conf

ENV CATALINA_APPS=${CATALINA_HOME}/webapps

RUN apt-get update \
        && apt-get -y install wget 

# Download and extract Pinpoint collector and web
RUN set -u \
        && mkdir -p ${PINPOINT_HOME}/collector ${PINPOINT_HOME}/web ${PINPOINT_CONF_DIR} \
        && cd ${PINPOINT_HOME}/collector \
        && wget https://github.com/naver/pinpoint/releases/download/${PINPOINT_VERSION}/pinpoint-collector-${PINPOINT_VERSION}.war \
        && unzip pinpoint-collector-${PINPOINT_VERSION}.war \
        && rm pinpoint-collector-${PINPOINT_VERSION}.war \
        && cd ${PINPOINT_HOME}/web \
        && wget https://github.com/naver/pinpoint/releases/download/${PINPOINT_VERSION}/pinpoint-web-${PINPOINT_VERSION}.war \
        && unzip pinpoint-web-${PINPOINT_VERSION}.war \
        && rm pinpoint-web-${PINPOINT_VERSION}.war

# Rename ROOT and gen symbolic link
RUN set -u \
        && mv ${CATALINA_APPS}/ROOT ${CATALINA_APPS}/default_app \
        && ln -s ${CATALINA_APPS}/default_app ${CATALINA_APPS}/ROOT

# Download and extract Hbase for checking whether tables exist on Hbase
ENV HBASE_VERSION=1.2.1
ENV HBASE_HOME=/opt/hbase-${HBASE_VERSION}
ENV HBASE_CONF_DIR=${HBASE_HOME}/conf

RUN set -u \
    && cd /opt \
#        && wget http://apache.mirror.cdnetworks.com/hbase/hbase-${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && wget http://apache.mirror.cdnetworks.com/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar xvzf hbase-${HBASE_VERSION}-bin.tar.gz \
    && rm hbase-${HBASE_VERSION}-bin.tar.gz

COPY hbase_scripts              /opt/hbase_scripts
COPY check_table_existence.sh   /opt/check_table_existence.sh
COPY hbase_tables.list          /opt/hbase_tables.list
COPY start                      /opt/start
COPY tools.sh                   /opt/tools.sh
COPY conf                       ${PINPOINT_CONF_DIR}
COPY hbase_conf                 ${HBASE_CONF_DIR}

WORKDIR ${PINPOINT_HOME}
ENTRYPOINT ["/opt/start"]
#CMD ["/opt/start"]

