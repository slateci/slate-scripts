# Overview #

This fold contains breakdown scripts to install SLATE a edge cluster based on the documentation located at http://slateci.io/docs/quickstart/quickstart-cluster-install.html.

# Quick Start #

## Set Cluster Identity ##

In file 00-set-cluster-id.sh, set values for the following variables.

```
INITIALGROUP=
CLUSTERNAME=
ORGNAME=
IPPOOL=
SLATE_TOKEN=
```


## Install Kubernetes Master ##

On the Kubernetes master node, run the following command in order:
```
00-set-cluster-id.sh
01-install-slate-cli.sh
02-install-access-token.sh
02-install-access-token.sh.clemson
03-tweak-system-configuration.sh
04-install-docker.sh
05-install-kubernetes.sh
05m-init-kubernetes-control.sh
05m-print-join-command.sh
06-config-admin-user.sh
07-install-network-plugin.sh
08-setup-load-balancer.sh
09-install-slate-client.sh
10-join-federation.sh
11-install-osg-squid.sh
12-install-cvmfs.sh
```

## Install Kubernetes Work Node ##

On a work node, run the following command in oder:

```
00-set-cluster-id.sh
01-install-slate-cli.sh
02-install-access-token.sh
02-install-access-token.sh.clemson
03-tweak-system-configuration.sh
04-install-docker.sh
05-install-kubernetes.sh
05w-join-local-cluster.sh
```

