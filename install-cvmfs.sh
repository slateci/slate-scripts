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
# Instance to label use case of Frontier Squid deployment
# Generates app name as "osg-frontier-squid-[Instance]"
# Enables unique instances of Frontier Squid in one namespace
Instance: cvmfs

Service:
  # Port that the service will utilize.
  Port: 3128
  # Controls how your service is can be accessed. Valid values are:
  # - LoadBalancer - This ensures that your service has a unique, externally
  #                  visible IP address
  # - NodePort - This will give your service the IP address of the cluster node 
  #              on which it runs. If that address is public, the service will 
  #              be externally accessible. Using this setting allows your 
  #              service to share an IP address with other unrelated services. 
  # - ClusterIP - Your service will only be accessible on the cluster's internal 
  #               kubernetes network. Use this if you only want to connect to 
  #               your service from other services running on the same cluster. 
  ExternalVisibility: ClusterIP

SquidConf:
  # The amount of memory (in MB) that Frontier Squid may use on the machine.
  # Per Frontier Squid, do not consume more than 1/8 of system memory with Frontier Squid
  CacheMem: 128
  # The amount of disk space (in MB) that Frontier Squid may use on the machine.
  # The default is 10000 MB (10 GB), but more is advisable if the system supports it.
  # Current limit is 999999 MB, a limit inherent to helm's number conversion system.
  CacheSize: 10000
  # The range of incoming IP addresses that will be allowed to use the proxy.
  # Multiple ranges can be provided, each seperated by a space.
  # Example: 192.168.1.1/32 192.168.2.1/32
  # Use 0.0.0.0/0 for open access.
  # The default set of ranges are those defined in RFC 1918 and typically used 
  # within kubernetes clusters. 
IPRange: 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
EOF

slate app install osg-frontier-squid --group $INITIALGROUP --cluster $CLUSTERNAME --conf squidconfig

rm -rf squidconfig

export CLUSTER_IP=$(kubectl get --namespace slate-group-$INITIALGROUP -o jsonpath="{.spec.clusterIP}" service osg-frontier-squid-cvmfs)

echo $CLUSTER_IP

echo "Adding CVMFS"

kubectl create namespace cvmfs

sleep 1s

yum install git 

git clone https://github.com/Mansalu/prp-osg-cvmfs.git

cd prp-osg-cvmfs

git checkout slate

cd ..

sleep 1s

cat << EOF > default.local 
CVMFS_SERVER_URL="http://cvmfs-s1bnl.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1fnal.opensciencegrid.org:8000/cvmfs/@fqrn@;http://cvmfs-s1goc.opensciencegrid.org:8000/cvmfs/@fqrn@"
CVMFS_KEYS_DIR=/etc/cvmfs/keys/opensciencegrid.org/
CVMFS_USE_GEOAPI=yes
CVMFS_HTTP_PROXY="http://$CLUSTER_IP:3128"
CVMFS_QUOTA_LIMIT=25000
CVMFS_REPOSITORIES=atlas.cern.ch,atlas-condb.cern.ch,atlas-nightlies.cern.ch,sft.cern.ch,geant4.cern.ch,grid.cern.ch,cms.cern.ch,oasis.opensciencegrid.org
EOF

kubectl create configmap cvmfs-osg-config -n cvmfs --from-file=default.local

sleep 1s

rm -rf default.local

kubectl create -f  prp-osg-cvmfs/k8s/cvmfs/accounts/

sleep 4s

kubectl create -f prp-osg-cvmfs/k8s/cvmfs/csi-processes/

sleep 4s

kubectl create -f prp-osg-cvmfs/k8s/cvmfs/storageclasses/

rm -rf prp-osg-cvmfs

kubectl get all -n cvmfs
