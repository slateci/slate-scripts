git clone https://github.com/Mansalu/prp-osg-cvmfs.git

git checkout slate

kubectl delete configmap -n cvmfs --all

kubectl delete -f prp-osg-cvmfs/k8s/cvmfs/storageclasses/

kubectl delete -f prp-osg-cvmfs/k8s/cvmfs/csi-processes/

kubectl delete -f prp-osg-cvmfs/k8s/cvmfs/accounts/

kubectl delete namespace cvmfs --force --grace-period=0

rm -rf prp-osg-cvmfs
