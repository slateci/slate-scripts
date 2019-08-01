echo "set up load balancer"

source 00-set-cluster-id.rc

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

echo << EOF > metallb-config.yaml
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
      - $IPPOOL
EOF

kubectl create -f metallb-config.yaml
rm metallb-config.yaml

