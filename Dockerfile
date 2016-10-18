FROM quay.io/geodocker/base:0.1

ENV ACCUMULO_VERSION 1.7.2
ENV GEOSERVER_VERSION 2.9.0
ENV GEOMESA_VERSION 1.2.5
ENV GEOWAVE_VERSION 0.9.3
ENV TOMCAT_VERSION 8.0.35
ENV CATALINA_OPTS "-Xmx4g -XX:MaxPermSize=512M -Duser.timezone=UTC -server -Djava.awt.headless=true"

# Install tomcat
RUN set -x \
  && groupadd tomcat \
  && useradd -M -s /bin/nologin -g tomcat -d /opt/tomcat tomcat \
  && mkdir -p /opt/tomcat/webapps/geoserver \
  && curl -sS  https://archive.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
  | tar -zx -C /opt/tomcat --strip-components=1

RUN set -x \
  && curl -sS -L -o /tmp/geoserver-war.zip \
    http://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/geoserver-${GEOSERVER_VERSION}-war.zip \
  && unzip /tmp/geoserver-war.zip geoserver.war -d /tmp \
  && unzip /tmp/geoserver.war -d /opt/tomcat/webapps/geoserver \
  && rm -rf /tmp/geoserver-war.zip /tmp/geoserver.war /opt/tomcat/webapps/geoserver/META-INF

# Install geoserver WPS plugin
RUN set -x \
  && curl -sS -L -o /tmp/geoserver-wps.zip \
    http://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/extensions/geoserver-${GEOSERVER_VERSION}-wps-plugin.zip \
  && unzip -j /tmp/geoserver-wps.zip -d /opt/tomcat/webapps/geoserver/WEB-INF/lib/ \
  && rm -rf /tmp/geoserver-wps.zip

# Install geomesa specific geoserver jar
COPY geomesa-accumulo-distributed-runtime-${GEOMESA_VERSION}.jar /opt/tomcat/webapps/geoserver/WEB-INF/lib/

# Install jars for geomesa/geowave integration
RUN set -x \
  && cd /opt/tomcat/webapps/geoserver/WEB-INF/lib/ \
  && wget -nv http://repo1.maven.org/maven2/org/apache/accumulo/accumulo-core/${ACCUMULO_VERSION}/accumulo-core-${ACCUMULO_VERSION}.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/accumulo/accumulo-fate/${ACCUMULO_VERSION}/accumulo-fate-${ACCUMULO_VERSION}.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/accumulo/accumulo-server-base/${ACCUMULO_VERSION}/accumulo-server-base-${ACCUMULO_VERSION}.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/accumulo/accumulo-trace/${ACCUMULO_VERSION}/accumulo-trace-${ACCUMULO_VERSION}.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/thrift/libthrift/0.9.3/libthrift-0.9.3.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/zookeeper/zookeeper/3.4.6/zookeeper-3.4.6.jar \
  && wget -nv http://repo1.maven.org/maven2/commons-configuration/commons-configuration/1.10/commons-configuration-1.10.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/hadoop/hadoop-auth/2.7.2/hadoop-auth-2.7.2.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/2.7.2/hadoop-common-2.7.2.jar \
  && wget -nv http://repo1.maven.org/maven2/org/apache/hadoop/hadoop-hdfs/2.7.2/hadoop-hdfs-2.7.2.jar \
  && wget -nv http://central.maven.org/maven2/org/apache/htrace/htrace-core/3.1.0-incubating/htrace-core-3.1.0-incubating.jar

RUN set -x \
  && chown root /opt/tomcat/webapps/geoserver/WEB-INF/lib/* \
  && chgrp root /opt/tomcat/webapps/geoserver/WEB-INF/lib/*

COPY server.xml /opt/tomcat/conf/server.xml
VOLUME ["/opt/tomcat/webapps/geoserver/data"]
EXPOSE 9090
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
