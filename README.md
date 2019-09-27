# k8sCache
Apache Geode on k8s

#requirements

# features

# How to run
1.install k8s
2.install helm
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
