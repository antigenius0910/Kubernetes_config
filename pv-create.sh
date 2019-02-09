#!/bin/bash

set -x 

# Required parameters for running this script
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Usage : $0 <PV NUMBER>"
        exit 1
fi


cat <<EOF > pv$1.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv$1
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: 192.168.5.178
    path: /mnt/data_remote/kubernetes/kubeflow/pv$1
EOF

kubectl apply -f pv$1.yaml 
