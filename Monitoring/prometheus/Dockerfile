FROM openjdk:8-jre-alpine

WORKDIR /opt/prometheus
COPY jmx_prometheus_httpserver.jar .
COPY runJMXExporter.sh /opt/prometheus
CMD /opt/prometheus/runJMXExporter.sh 127.0.0.1