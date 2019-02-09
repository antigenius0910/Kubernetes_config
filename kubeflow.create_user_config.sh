#!/bin/bash

set -x 

# Required parameters for running this script
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Usage : $0 <USER_NAME>"
        exit 1
fi

KUBE_URL=https://172.29.100.185:6443
CLUSTER=juju-cluster
CRT_DAYS=365
USER_NAME=$1
#Cluster wild PKI location (easyrsa)
#/var/lib/juju/agents/unit-easyrsa-0/charm/EasyRSA-3.0.1/pki/ca.crt
#/var/lib/juju/agents/unit-easyrsa-0/charm/EasyRSA-3.0.1/pki/private/ca.key
CA_CRT_PATH=/root/certs/ca.crt
CA_KEY_PATH=/root/certs/ca.key

#Create user and its config file
openssl genrsa -out /root/certs/$USER_NAME.key 2048
openssl req -new -key /root/certs/$USER_NAME.key -out /root/certs/$USER_NAME.csr -subj "/CN=$USER_NAME/O=example"
openssl x509 -req -in /root/certs/$USER_NAME.csr -CA $CA_CRT_PATH -CAkey $CA_KEY_PATH -CAcreateserial -out /root/certs/$USER_NAME.crt -days $CRT_DAYS
openssl x509 -in /root/certs/$USER_NAME.crt -text -noout
export KUBECONFIG=/root/k8s-$USER_NAME.conf
kubectl config set-cluster $CLUSTER --server="$KUBE_URL" --certificate-authority="$CA_CRT_PATH" --embed-certs=true
kubectl config set-credentials $USER_NAME --client-certificate=/root/certs/$USER_NAME.crt  --client-key=/root/certs/$USER_NAME.key --embed-certs=true
kubectl config set-context $USER_NAME-context --cluster=$CLUSTER --user=$USER_NAME --namespace=example
kubectl config set-context kubeflow-context --cluster=$CLUSTER --user=$USER_NAME --namespace=kubeflow
kubectl config use-context $USER_NAME-context

#Create example namespace permission/rolebinding setup for this user 
cat <<EOF > default_user.yaml 
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USER_NAME-example
  namespace: example
subjects:
- kind: User
  name: $USER_NAME
  namespace: example
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF

#Create kubeflow namespace permission/rolebinding setup for this user 
cat <<EOF > kubeflow_user.yaml 
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USER_NAME-kubeflow
  namespace: kubeflow
subjects:
- kind: User
  name: $USER_NAME
  namespace: kubeflow
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF

#Create kubeflow cluster permission/rolebinding setup for this user 
#cat <<EOF > kubeflow_admin.yaml 
#kind: ClusterRoleBinding
#apiVersion: rbac.authorization.k8s.io/v1
#metadata:
#  name: $USER_NAME-kubeflow
#  namespace: kubeflow
#subjects:
#- kind: User
#  name: $USER_NAME
#  namespace: kubeflow
#  apiGroup: rbac.authorization.k8s.io
#roleRef:
#  kind: ClusterRole
#  name: cluster-admin
#  apiGroup: rbac.authorization.k8s.io
#EOF

#Apply this rolebinding as admin 
kubectl apply -f default_user.yaml --kubeconfig /root/.kube/config
kubectl apply -f kubeflow_user.yaml --kubeconfig /root/.kube/config
#kubectl apply -f kubeflow_admin.yaml --kubeconfig /root/.kube/config
