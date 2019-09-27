# k8sCache
Apache Geode on k8s

# Requirements
-Kubernets v1.9+

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


# Parameters & default value when creating a geode cluster or wan gateways by helm install command:

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
1.install k8s
https://kubernetes.io/docs/tasks/tools/install-kubectl/

2.install helm
https://helm.sh/docs/using_helm/

3.clone the k8sCache charts & examples.
```
git clone https://github.com/GSSJacky/k8sCache.git
cd k8sCache
```

4.create a geode cluster.
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


5.confirm the cluster from pulse:
http://localhost:32100/pulse

6.confirm from gfsh console:
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
