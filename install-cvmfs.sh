### You should change these:

# The name of your cluster as registered in SLATE
CLUSTERNAME="CLUSTER NAME"
# The initial group who will be able to access this cluster.
# Supplementary groups can be added later.
INITIALGROUP="GROUP NAME"
# Organization name. Simplest to keep this as a single word or acronym for now
ORGNAME="myorg"


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

yum -y install git 

export CLUSTER_IP=$(kubectl get --namespace slate-group-$INITIALGROUP -o jsonpath="{.items[0].spec.clusterIP}" services)

git clone https://github.com/Mansalu/prp-osg-cvmfs.git

cd prp-osg-cvmfs

git checkout slate

cd ..

cat << EOF > default.local 
CVMFS_SERVER_URL="http://cvmfs-s1bnl.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1fnal.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1goc.opensciencegrid.org:8000/cvmfs/@fqrn@"
CVMFS_KEYS_DIR=/etc/cvmfs/keys/opensciencegrid.org/
CVMFS_USE_GEOAPI=yes
CVMFS_HTTP_PROXY="http://$CLUSTER_IP:3128"
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
