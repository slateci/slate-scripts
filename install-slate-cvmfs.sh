#!/bin/bash

# First, go here: https://portal.slateci.io/
# And visit the "CLI Access" page to get your token and install it to your
# server.

### You should change these:

# The name of your cluster as registered in SLATE
CLUSTERNAME="CLUSTER NAME"
# The initial group who will be able to access this cluster.
# Supplementary groups can be added later.
INITIALGROUP="GROUP NAME"
# Organization name. Simplest to keep this as a single word or acronym for now
ORGNAME="ORG NAME"
# The pool of IP address you want the 'load balancer' to allocate.
IPPOOL="IP RANGE OR CIDR"

############################

if [[ -f ~/.slate/token ]]; then
  echo "token exists, continuing.."
else
  echo "SLATE token doesn't exist. Please view the header of this script before continuing."
  exit 1
fi

echo -n "Checking OS vendor... " 
VENDOR=$(hostnamectl | grep 'Operating System')
echo $VENDOR | grep -e 'CentOS\|Scientific\|Red\ Hat' 2>&1 >/dev/null
if [ $? -eq 0 ]; then
  echo "Seems to be a Red Hat variant"
  echo -n "Checking version... "
  echo $VENDOR | grep 7 2>&1 > /dev/null  
    if [ $? -ne 0 ]; then
      echo "Doesn't seem to be EL7. Cowardly refusing to continue."
      exit 1
    else 
      echo "Seems to be EL7"
    fi
else
  echo "Doesn't seem to be Red Hat variant. Cowardly refusing to continue."
  exit 1
fi

echo -n "Checking SELinux status... "
SESTATUS=$(sestatus | awk '{print $3}')
if [[ $SESTATUS == "enabled" ]]; then
  echo "SELinux is enabled. Disabling... may require reboot"
  # Set SELinux in permissive mode (effectively disabling it)
  setenforce 0
  sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
else
  echo "SELinux is disabled or permissive. Continuing..."
fi

echo "Disabling swap..."
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab

echo "Installing Docker CE..."
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl enable --now docker

echo "Installing Kubernetes YUM repo..."
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

echo "Installing Kubelet, Kubeadm, Kubectl..."
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

echo "Enabling Kubelet..."
systemctl enable --now kubelet

echo "Adding sysctl tweaks for EL7..."
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "Initializing Kubernetes cluster with 192.168 RFC1918 range for Pod CIDR..."
kubeadm init --pod-network-cidr=192.168.0.0/16
if [ "$?" -ne 0 ]; then
  echo "kubeadm init failed" 1>&2
  exit 1
fi

echo "Copying Kubernetes config to root's homedir..."
mkdir -p ~/.kube/
cp -f /etc/kubernetes/admin.conf ~/.kube/config


echo "Installing Calico networking plugin..."
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml

echo "Removing Master taint, so we can run pods on a single-node cluster..."
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "Installing MetalLB load balancer..."
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

cat << EOF > metallb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${IPPOOL}
EOF

kubectl create -f metallb-config.yaml
rm -f metallb-config.yaml

echo "Installing SLATE repository and client..."
cat << EOF > /etc/yum.repos.d/slate.repo
[slate-client]
name=SLATE-client
baseurl=https://jenkins.slateci.io/artifacts/client/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

yum install slate-client -y

slate cluster create --group $INITIALGROUP $CLUSTERNAME --org $ORGNAME -y

echo "Deploying squid proxy instance"

cat << EOF > squidconfig
Instance: cvmfs
Service:
  Port: 3128 
  ExternalVisibility: ClusterIP
SquidConf:
  CacheMem: 128
  CacheSize: 10000
IPRange: 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
EOF

slate app install osg-frontier-squid --group $INITIALGROUP --cluster $CLUSTERNAME --conf squidconfig

rm -rf squidconfig

echo "Adding CVMFS"

kubectl create namespace cvmfs

yum install git 

git clone https://github.com/Mansalu/prp-osg-cvmfs.git

cd prp-osg-cvmfs

git checkout slate

cd ..

cat << EOF > default.local 
CVMFS_SERVER_URL="http://cvmfs-s1bnl.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1fnal.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1goc.opensciencegrid.org:8000/cvmfs/@fqrn@"
CVMFS_KEYS_DIR=/etc/cvmfs/keys/opensciencegrid.org/
CVMFS_USE_GEOAPI=yes
CVMFS_HTTP_PROXY="http://osg-frontier-squid-cvmfs.slate-group-$INITIALGROUP.svc.local:3128"
CVMFS_QUOTA_LIMIT=5000
CVMFS_REPOSITORIES=atlas.cern.ch,atlas-condb.cern.ch,atlas-nightlies.cern.ch,sft.cern.ch,geant4.cern.ch,grid.cern.ch,cms.cern.ch,oasis.opensciencegrid.org
EOF

kubectl create configmap cvmfs-osg-config -n cvmfs --from-file=default.local

rm -rf default.local

kubectl create -f  prp-osg-cvmfs/k8s/cvmfs/accounts/

kubectl create -f prp-osg-cvmfs/k8s/cvmfs/csi-processes/

kubectl create -f prp-osg-cvmfs/k8s/cvmfs/storageclasses/

rm -rf prp-osg-cvmfs

kubectl get all -n cvmfs

echo "Your SLATE cluster has been successfully installed"
