---
layout: post
title: "[EN] - CoreOS: first impressions"
description: "My explanation of what I learned about CoreOS"
category: devops
keywords: linux, devops, docker, container, coreos, cluster, etcd, fleet, systemd
---

> This post isn't a tutorial to install or use CoreOS, but rather my 
impressions of the system.

### Introduction

[CoreOS](https://coreos.com/) is a Linux distribution redesigned to provide the necessary 
resources to maintain a modern, highly scalable and easy to manage 
infrastructure.

Unlike Ubuntu or Debian, CoreOS doesn't have a package manager, so any 
software that you want to install will use Docker containers by default.
[Docker provides process isolation](https://docs.docker.com/introduction/understanding-docker/#the-underlying-technology) and CoreOS take advantage of that, 
allowing applications to be distributed in a cluster easily.

Another difference between most Linux distributions is that the system 
is maintained as a whole, so the CoreOS makes use of a double root 
partition scheme.
This scheme allows the system to install the update on a different root 
partition that is in use.

See the example, the system is initialized to use the partition `A`, the 
CoreOS checks for available updates, then downloads and installs it in 
the `B` partition. This ensures that network boundaries rates and I/O do 
not cause an overload in applications in progress, as this update 
process is isolated with cgroups.

![coreos update example](/images/update-coreos.png)

To complete the upgrade the machine must be rebooted and that the system 
will use the `B` partition, if any problem happens while updating the 
system, CoreOS will perform a rollback and return to use the `A` partition.

### Etcd

To distribute the data for configuration between nodes in a cluster, the 
CoreOS distribution use a service called [ETCD](https://github.com/coreos/etcd) which is a global 
`key-value` scheme responsible for managing the discovery of services, 
which allows the configuration of dynamic applications.

Application containers running on your cluster can read and write data 
into etcd. Common examples are storing database connection details, 
cache settings, feature flags, and [more](https://coreos.com/using-coreos/etcd/).

In each ETCD the client node is running and configured to communicate 
with other nodes in the cluster:

![etcd cluster](/images/etcd-cluster.png)

The operation of ETCD to share configuration data is based on an REST 
API (HTTP and JSON) by default in: [http://127.0.0.1:4001/v2/keys/](#).
Use docker with ETCD is very interesting, because ETCD runs on every 
host at the same ip address. This way you can send a single container 
for different nodes in a cluster.

![etcd api](/images/etcd-api.png)

### Fleet

For clusters control the system provides a tool called [Fleet](https://github.com/coreos/fleet), it 
works as a process manager that facilitates the configuration of 
applications from a single point.

In the cluster environment, each node has its own `systemd`, which is a 
boot system to manage local services. The fleet kicks in providing an 
interface to control each present systemd on the cluster nodes. 
This way you can start or stop services, list information of running 
processes across the cluster.

Besides that, the `fleet` controls the processes distribution mechanism 
choosing the less busy hosts to start the services. All this flexibility 
ensures a simple implementation to separate nodes in containers:

![fleet manager](/images/fleet-manager.png)

### Conclusion

The CoreOS is very different from most Linux distributions that I'm 
used to, its design was created to facilitate the management of clusters 
and portability of applications.

I'm impressed by the CoreOS project and soon I'll invest more time in it.
Next, I'll post about creating clusters with CoreOS + Docker. Tune in to 
learn more about Docker and CoreOS.

### References

- [https://coreos.com/](https://coreos.com/)

- [https://coreos.com/using-coreos/docker/](https://coreos.com/using-coreos/docker/)

- [https://coreos.com/using-coreos/etcd/](https://coreos.com/using-coreos/etcd/)

- [https://coreos.com/using-coreos/clustering/](https://coreos.com/using-coreos/clustering/)

- [https://github.com/coreos/etcd](https://github.com/coreos/etcd)

- [https://github.com/coreos/fleet](https://github.com/coreos/fleet)
