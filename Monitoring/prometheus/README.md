# Prometheus module for k8sCache
The goal of this implementation is to add a prometheus jmx exporter module for k8sCache by leveraging jmx_prometheus_httpserver: converting geode jmx Mbean as http format which can be recognized by prometheus servers.

# Requirements
-Kubernets v1.9+

-Docker 18.09+

-Prometheus v2.2.1+

-[JMX Exporter v0.12.0](https://mvnrepository.com/artifact/io.prometheus.jmx/jmx_prometheus_httpserver)

# How to setup Prometheus on k8s 
Setup Prometheus Monitoring On Kubernetes Cluster [Reference](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/)
1.Create a Namespace 
```
kubectl create namespace monitoring
```

2.Create ClusterRole Config which assigns cluster reader permission to this namespace so that Prometheus can fetch the metrics from Kubernetes API’s.
For example:
[ClusterRole Config](https://raw.githubusercontent.com/bibinwilson/kubernetes-prometheus/master/clusterRole.yaml)
```
kubectl create -f clusterRole.yaml
```

3.Create a Config Map with all the prometheus scrape config and alerting rules, which will be mounted to the Prometheus container in /etc/prometheus as prometheus.yaml and prometheus.rules files.
For example:
[Prometheus Config](https://raw.githubusercontent.com/bibinwilson/kubernetes-prometheus/master/config-map.yaml)
```
kubectl create -f config-map.yaml
```

4.Create a Prometheus Deployment.
For example:
prometheus-deployment.yaml
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: prometheus-deployment
  namespace: monitoring
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: prometheus-server
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus:v2.12.0
          args:
            - "--config.file=/etc/prometheus/prometheus.yml"
            - "--storage.tsdb.path=/prometheus/"
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: prometheus-config-volume
              mountPath: /etc/prometheus/
            - name: prometheus-storage-volume
              mountPath: /prometheus/
      volumes:
        - name: prometheus-config-volume
          configMap:
            defaultMode: 420
            name: prometheus-server-conf
  
        - name: prometheus-storage-volume
          emptyDir: {}
```

```
kubectl create  -f prometheus-deployment.yaml 

kubectl get deployments --namespace=monitoring
```

5.Exposing Prometheus as a Service
For example:
prometheus-service.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
  annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/path:   /
      prometheus.io/port:   '8010'  
spec:
  selector: 
    app: prometheus-server
  type: NodePort  
  ports:
    - port: 8010
      targetPort: 9090 
      nodePort: 31000
```

```
kubectl create -f prometheus-service.yaml --namespace=monitoring
```

# How to create a deployment of geode jmx exporter by jmx exporter httpserver module
1.Download [jmx exporter httpserver module](https://mvnrepository.com/artifact/io.prometheus.jmx/jmx_prometheus_httpserver) and rename it as "jmx_prometheus_httpserver.jar".
https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/0.12.0/jmx_prometheus_httpserver-0.12.0.jar

2.build the jmx exporter Docker image and push it to a docker image registery such as docker hub.
```
docker build . -t jackyxu2018/jmxexporter

docker push jackyxu2018/jmxexporter
```

3.create jmx exporter deployment and service accordingly with the uploaded docker image, set the 
For example:
jmx_exporter_deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jmxexporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jmxexporter
  template:
    metadata:
      labels:
        app: jmxexporter
    spec:
      containers:
      - name: jmxexporter
        image: jackyxu2018/jmxexporter
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: "http"
        env:
        #Define the environment variable, the value is required to set the correct cluster's locator service name here which you want to monitor.
        - name: JMX_HOST
          value: "gemfire-cluster1-geode"
        # The other way to pass the cluster name which you want to monitor to the jmx exporter  
        #command: ["/opt/prometheus/runJMXExporter.sh"]
        #args: ["gemfire-cluster1-geode"]

---
apiVersion: v1
kind: Service
metadata:
  name: jmxexporterservice
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/jvm-scrape: "true"
    prometheus.io/jvm-port: "8080"
    prometheus.io/jvm-path: "/metrics"
spec:
  selector:
    app: jmxexporter
  ports:
  - name: http
    protocol: TCP
    port: 8080
    nodePort: 32399
  type: NodePort
```

```
kubectl apply -f jmx_exporter_deployment.yaml
```

4.Access prometheus jmx exporter service by nodePort:32399, you can get the geode cluster's metrics.
```
curl -k localhost:32399/metrics
```

5.Access prometheus service, open a metrics of geode from "Graph".
http://localhost:31000/graph
