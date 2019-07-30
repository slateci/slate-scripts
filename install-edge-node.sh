#!/bin/bash

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

echo "All done installing edge node requirements"
echo "On the master, please run the following command: "
echo "   kubeadm create token --print-join-command "
echo "and run the output here."
