# How to Install CVMFS on SLATE a Cluster

## Prerequisites

-Ruunning SLATE Cluster
-kubectl access to your SLATE Cluster
-A running instance of squid

## How to get started with squid

Learn how run squid as a SLATE application: 

https://github.com/slateci/slate-catalog/tree/master/stable/osg-frontier-squid/osg-frontier-squid

## Getting the required YAML Manifests 

`git clone https://github.com/sfiligoi/prp-osg-cvmfs`

You'll want to use the master branch, and you can ignore the frontier related deployment files.

Everything you need is in `prp-osg-cvmfs/k8s/cvmfs`

## Setup the CVMFS Namespace

Everything should run in a namespace on your cluster called cvmfs.

`kubectl create namespace cvmfs`

## Setup the kubernetes configmap

We'll use a configmap to mount the default.local configuration file the provisioner needs. You will need the IP of your squid proxy instance to do this. 

Make sure you are in the `prp-osg-cvmfs/k8s/cvmfs` directory
`cd prp-osg-cvmfs/k8s/cvmfs`

Rename the template file
`mv default.local.template default.local`
Youre config file must be named `default.local` or you will get an error.

Edit the configuration with your favorite text editor
`vim default.local`

Simply replace FRONTIERSQUIDSERVICE with the IP of your squid service. 
CVMFS_HTTP_PROXY="http://FRONTIERSQUIDSERVICE:3128"

Save and exit.

Create the kubernetes config map from the default.local configuration file we just editted.
`kubectl create configmap cvmfs-osg-config -n cvmfs --from-file=default.local`

## Deploy the Service Accounts

Again be sure you are working in the `prp-osg-cvmfs/k8s/cvmfs` directory.

`kubectl create -f accounts/`

## Deploy Provisioner and CSI proccesses 

`kubectl create -f csi-processes/`

## Setup the StorageClasses

`kubectl create -f storageclasses/`

In order to use HTCondor in SLATE you will need to setup an additional StorageClass for SPT

Create a new file in your favorite text editor 
`vim spt-storageclass.yaml`

Paste the following:

  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: csi-cvmfs-spt
    namespace: cvmfs
  provisioner: csi-cvmfsplugin
  parameters:
  repository: spt.opensciencegrid.org

Create the SPT StorageClass in Kubernetes
`kubectl create -f spt-storageclass.yaml`

## OPTIONAL Create Persistent Volume Claims

The HTCondoor chart will automatically setup PVCs in the correct namespace. If you plan to use CVMFS outside of HTCondor you will need PVCs in the namespace where your application is running.

`kubectl create -n <YOUR DESIRED NAMESPACE> -f pvcs/`
