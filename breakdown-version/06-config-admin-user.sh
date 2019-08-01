mkdir -p ~/.kube
# note specific user of superuser privileges to copy the original file
sudo cp -f /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER ~/.kube/config

kubectl get nodes
