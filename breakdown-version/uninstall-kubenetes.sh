#!/bin/bash

MASTER=
NODE_TO_DELETE=
#MASTER=slate002.clemson.edu
#NODE_TO_DELETE=slate001.clemson.edu

check_variable() {
    for VAR in $@; do
        VALUE="$VAR"
        if [ -z ${!VALUE} ]; then
            echo "Please set a correct value for $VAR"
            exit 1
        else
            echo "$VAR = \"${!VALUE}"\"
        fi
    done
}


remove_from_master() {
    kubectl drain $NODE_TO_DELETE --delete-local-data --force --ignore-daemonsets
    kubectl delete node $NODE_TO_DELETE
}

remove_from_node() {
    kubeadm reset
    sudo yum remove kubeadm kubectl kubelet kubernetes-cni kube*
    sudo yum autoremove
    sudo rm -rf ~/.kube
}

check_variable MASTER NODE_TO_DELETE

THIS_HOST=$(hostname -f)
if [ $THIS_HOST == $MASTER ]; then
    remove_from_master
else
    remove_from_node
fi
