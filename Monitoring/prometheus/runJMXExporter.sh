#!/bin/sh

if [ "x$JMX_HOST" == "x" ]; then
    #get parameters from script
    JMXHOST=$1
    JMXUSER=$2
    JMXPASSWORD=$3
    FROMFLAG="from script parameters"
else
    #get parameters from env variables(set from configmap)
    JMXHOST=${JMX_HOST}
    JMXUSER=${JMX_USER}
    JMXPASSWORD=${JMX_PASSWORD}
    FROMFLAG="from env varilables"
fi

cat << EOF >> ./jmx-config.yaml
ssl: false
hostPort: $JMXHOST:1099
username: $JMXUSER
password: $JMXPASSWORD
EOF

echo "Exporting $JMXHOST:1099 's jmx mettrics $FROMFLAG"
#java -Djavax.net.ssl.trustStore=/etc/jmx-secret/store.jks -Djavax.net.ssl.trustStorePassword=${STORE_PW} -jar jmx_prometheus_httpserver.jar 0.0.0.0:8080 /tmp/jmx-config.yaml
java -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -jar /opt/prometheus/jmx_prometheus_httpserver.jar 8080 /opt/prometheus/jmx-config.yaml
