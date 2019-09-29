# k8sCache
This repository is an helm chart implementation on Apache Geode, which can help create geode cluster/wan gateway under k8s/pks quickly with full features of apache geode.

This readme contains:

-Requirements

-Feature

-Chart's value list

-How to create a geode cluster by k8sCache

-How to run the spring boot client with k8sCache cluster

-How to create a wan by k8sCache

-How to scale up and scale down


# Requirements
-Kubernets v1.9+ (Tested with PKS 1.3.6+,1.4.0+)

-Docker 18.09+

-Helm v2.14+

# Features
We are trying to fully implement all the features of Apache Geode under kubernetes platform.

-High Read-and-Write Throughput

-Low and Predictable Latency

-High Scalability (HA)

-Continuous Availability/Continuous Querying (Durable client/CQ)

-Reliable Event Notifications (Pub/Sub)

-Parallelized Application Behavior on Data Stores (Function execution service)

-Shared-Nothing Disk Persistence

-Client/Server Capability (Java Client/ C++ / .Net Client Supported)

-Multisite Data Distribution (Wan gateway)

-Rest API Capability


# Parameters & default value when creating a cluster by helm command

```
#image parameters
image.repository=apachegeode/geode
image.tag=1.9.0
image.pullPolicy=IfNotPresent

#service parameters
service.type=ClusterIP # service type has ClusterIP / NodePort / LoadBalancer options
service.port=7070
service.pulse_nodeport=32100
service.locator_nodeport=32101
service.jmx_nodeport=32102
service.cacheserver_nodeport=32103
service.rest_nodeport=32200

#cluster plan parameters
config.num_locators=2
config.num_servers=3

#locators jvm parameters and system properties
locator.jvm_options="--J=-XX:CMSInitiatingOccupancyFraction=70"
locator.system_parameter_options="--J=-Dgemfire.member-timeout=10000 --J=-Dgemfire.enable-network-partition-detection=false"

#cacheservers jvm parameters and system properties 
cacheserver.jvm_options="--J=-XX:CMSInitiatingOccupancyFraction=70"  # the oter examples: "--J=-XX:MaxPermSize=256m --J=-XX:PermSize=256m --J=-XX:NewSize=256m --J=-XX:MaxNewSize=256m"
cacheserver.system_parameter_options="--J=-Dgemfire.member-timeout=10000 --J=-Dgemfire.enable-network-partition-detection=false"

#wan gateway parameters
wan.distributed_system_id=1
wan.enabled=false
wan.remote_locators="geode.remote1[9009],geode.remote2[9009]"

#locator/cacheserver heap size definition
memory.max_locators=1024m
memory.max_servers=2048m

#ingress parameters(this part is not full tested yet)
ingress.enabled=false
ingress.annotations={}
ingress.path=/
ingress.hosts=geode.local  #multiple values separated by "\,"
ingress.tls=[]

#cacheserver's rest api service parameters
rest.enabled=true
rest.port=9090
rest.ingress.enabled=true
rest.ingress.annotations={}
rest.ingress.path="/gemfire-api/v1/*"
rest.ingress.hosts=geode.local  #multiple values separated by "\,"
rest.ingress.tls=[]

```

# How to have a quick run in local k8s env
1.install docker in local env.

2.install k8s
https://kubernetes.io/docs/tasks/tools/install-kubectl/

3.install helm
https://helm.sh/docs/using_helm/

4.clone the k8sCache charts & examples.
```
git clone https://github.com/GSSJacky/k8sCache.git
cd k8sCache
```

5.create a geode cluster.
For example:
```
helm install \
--set service.type=NodePort \
--set config.num_locators=1 \
--set config.num_servers=1 \
--set memory.max_locators=512m \
--set memory.max_servers=512m \
--set image.tag=1.10.0 \
./K8SCache \
--name=gemfire-cluster1


NAME:   gemfire-cluster1
LAST DEPLOYED: Fri Sep 27 13:44:58 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Pod(related)
NAME                             READY  STATUS             RESTARTS  AGE
gemfire-cluster1-geode-0         0/1    ContainerCreating  0         0s
gemfire-cluster1-geode-server-0  0/1    ContainerCreating  0         0s

==> v1/Service
NAME                           TYPE      CLUSTER-IP     EXTERNAL-IP  PORT(S)                                        AGE
gemfire-cluster1-geode         NodePort  10.105.56.67   <none>       10334:32101/TCP,7070:32100/TCP,1099:32102/TCP  1s
gemfire-cluster1-geode-rest    NodePort  10.111.8.37    <none>       9090:32200/TCP                                 0s
gemfire-cluster1-geode-server  NodePort  10.101.131.63  <none>       40404:32103/TCP                                0s

==> v1/StatefulSet
NAME                           READY  AGE
gemfire-cluster1-geode         0/1    0s
gemfire-cluster1-geode-server  0/1    0s

==> v1beta1/Ingress
NAME                         HOSTS        ADDRESS  PORTS  AGE
gemfire-cluster1-geode-rest  geode.local  80       0s


NOTES:
1. To monitor Geode cluster run these commands:
  export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:32100/pulse
  ps:
  If you run kubernetes cluster in local env, you can use the below URL. 
  http://localhost:32100/pulse
```


6.confirm the cluster from pulse:
http://localhost:32100/pulse

7.confirm from gfsh console:
```
#Get the node ip:
echo $(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")

#Connect from gfsh console if you don't have gfsh locally:
jaxu_MBP:k8sCache jaxu$ docker run -i -t apachegeode/geode:1.10.0 gfsh
    _________________________     __
   / _____/ ______/ ______/ /____/ /
  / /  __/ /___  /_____  / _____  / 
 / /__/ / ____/  _____/ / /    / /  
/______/_/      /______/_/    /_/    1.10.0

Monitor and Manage Apache Geode
gfsh>connect --use-http --url=http://192.168.65.3:32100/gemfire/v1
Successfully connected to: GemFire Manager HTTP service @ http://192.168.65.3:32100/gemfire/v1

Cluster-1 gfsh>list members
Member Count : 2

             Name               | Id
------------------------------- | ----------------------------------------------
gemfire-cluster1-geode-server-0 | gemfire-cluster1-geode-server-0(gemfire-clus..
gemfire-cluster1-geode-0        | gemfire-cluster1-geode-0(gemfire-cluster1-ge..
```

# How to run the spring boot client example connecting with k8sCache clusters
1.create Pizza/Name regions by gfsh commands:
```
create region --name=Pizza --type=REPLICATE
create region --name=Name --type=REPLICATE
```

2.build the spring boot application image, push it into docker hub.

```
cd examples/pizzastoreapp

# build the application image basing on the Dockerfile
docker build . -t jackyxu2018/pizzastore

# modified the spring.data.gemfire.pool.locators which you want to connect in application.properties
path:
xxx/examples/pizzastoreapp/src/main/resources/application.properties

# push this image into docker hub or any other docker image registery such as habor
# to run the below command, you need to docker login at first.
docker push jackyxu2018/pizzastore

# deploy the this application into k8s cluster basing on the app.yaml (you can change the yaml file accordingly such as service spec.type)
kubectl create -f app.yaml

#confirm the pod's status
kubectl get pods
kubectl logs pizzastore-858f8cfcd6-ngvxq

# you can get service's port info by the below command
kubectl get svc -o wide

# confirm the status of this spring boot application by ping rest api
curl -k chttp://localhost:32321/ping
------
<h1>PONG!</h1>
------

# call the below rest api of spring boot application, it will put 3 pizza entries into cluster.
curl -k http://localhost:32321/preheatOven
------
<h1>OVEN HEATED!</h1>
------

# you can confirm the entries by the blow URL:
curl -k http://localhost:32321/pizzas
---------
[{"toppings":["CHICKEN","ARUGULA"],"name":"fancy","sauce":"ALFREDO"},{"toppings":["PARMESAN","CHICKEN","CHERRY_TOMATOES"],"name":"test","sauce":"PESTO"},{"toppings":["CHEESE"],"name":"plain","sauce":"TOMATO"}]jaxu_MBP:pizzastoreapp jaxu$ 
---------
```

# How to create two cluster with Bidirectional Replication across a WAN
1.Create Cluster1 via helm command:
ps:
two geode cluster required at least 2*(2*1024+3*2048)=2*8G=16G memory)

```
helm install \
--set wan.enabled=true \
--set wan.distributed_system_id=1 \
--set wan.remote_locators='gemfire-cluster2-geode[10334]' \
--set service.type=NodePort \
--set config.num_locators=2 \
--set config.num_servers=3 \
--set memory.max_locators=1024m \
--set memory.max_servers=2048m \
--set image.tag=1.10.0 \
./K8SCache \
--name=gemfire-cluster1

helm install \
--set wan.enabled=true \
--set wan.distributed_system_id=2 \
--set wan.remote_locators='gemfire-cluster1-geode[10334]' \
--set service.type=NodePort \
--set config.num_locators=2 \
--set config.num_servers=3 \
--set memory.max_locators=1024m \
--set memory.max_servers=2048m \
--set image.tag=1.10.0 \
./K8SCache \
--name=gemfire-cluster2
```

2.Set up gateway and create regions via gfsh
```
#Cluster1
gfsh>create gateway-sender --id=send_to_2 --remote-distributed-system-id=2 --enable-persistence=true
gfsh>create region --name=regionX --gateway-sender-id=send_to_2 --type=PARTITION_REDUNDANT
gfsh>create gateway-receiver --start-port=30000 --end-port=30001

#Cluster2
gfsh>create gateway-sender --id=send_to_1 --remote-distributed-system-id=1 --enable-persistence=true
gfsh>create region --name=regionX --gateway-sender-id=send_to_1 --type=PARTITION_REDUNDANT
gfsh>create gateway-receiver --start-port=30000 --end-port=30001
```

# How to scale up

```
$ kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
gemfire-cluster1-geode-0          1/1     Running   0          2d
gemfire-cluster1-geode-server-0   1/1     Running   0          2d
pizzastore-858f8cfcd6-ngvxq       1/1     Running   0          1d

$ kubectl scale statefulsets gemfire-cluster1-geode-server --replicas=2
statefulset.apps/gemfire-cluster1-geode-server scaled

$ kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
gemfire-cluster1-geode-0          1/1     Running   0          2d
gemfire-cluster1-geode-server-0   1/1     Running   0          2d
gemfire-cluster1-geode-server-1   1/1     Running   0          2m
pizzastore-858f8cfcd6-ngvxq       1/1     Running   0          1d
```

# How to scale down 
There is a data loss risk on partition regions if you want to scale down,please make sure that you have enough data redundancy copy with partition regions.
```
$ kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
gemfire-cluster1-geode-0          1/1     Running   0          2d
gemfire-cluster1-geode-server-0   1/1     Running   0          2d
gemfire-cluster1-geode-server-1   1/1     Running   0          3m
pizzastore-858f8cfcd6-ngvxq       1/1     Running   0          1d

$ kubectl scale statefulsets gemfire-cluster1-geode-server --replicas=1
statefulset.apps/gemfire-cluster1-geode-server scaled

$ kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
gemfire-cluster1-geode-0          1/1     Running   0          2d
gemfire-cluster1-geode-server-0   1/1     Running   0          2d
pizzastore-858f8cfcd6-ngvxq       1/1     Running   0          1d
```
