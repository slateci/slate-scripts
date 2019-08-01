if [ -e "k8-join-cmd.sh" ]; then
    chmod +x k8-join-cmd.sh
    basedir=$(pwd)
    sudo $basedir/k8-join-cmd.sh
else
    echo "Go to master node, run command \"sudo kubeadm token create --print-join-command\""
    echo "Then on work node, run the join command."
fi
