echo "Adding CVMFS"
source 00-set-cluster-id.rc

export CLUSTER_IP=$(kubectl get --namespace slate-group-$INITIALGROUP -o jsonpath="{.spec.clusterIP}" service osg-frontier-squid-cvmfs)
kubectl create namespace cvmfs

yum install git -y

git clone https://github.com/Mansalu/prp-osg-cvmfs.git

cd prp-osg-cvmfs

git checkout slate

cd k8s/cvmfs

cat << EOF > default.local
CVMFS_SERVER_URL="http://cvmfs-s1bnl.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1fnal.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1goc.opensciencegrid.org:8000/cvmfs/@fqrn@"
CVMFS_KEYS_DIR=/etc/cvmfs/keys/opensciencegrid.org/
CVMFS_USE_GEOAPI=yes
CVMFS_HTTP_PROXY="http://$CLUSTER_IP:3128"
CVMFS_QUOTA_LIMIT=5000
CVMFS_REPOSITORIES=atlas.cern.ch,atlas-condb.cern.ch,atlas-nightlies.cern.ch,sft.cern.ch,geant4.cern.ch,grid.cern.ch,cms.cern.ch,oasis.opensciencegrid.org
EOF

kubectl create configmap cvmfs-osg-config -n cvmfs --from-file=default.local

kubectl create -f  accounts/

kubectl create -f csi-processes/

kubectl create -f storageclasses/

