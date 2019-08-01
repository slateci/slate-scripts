echo "Deploying squid proxy instance"
source 00-set-cluster-id.rc

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

rm -f squidconfig

