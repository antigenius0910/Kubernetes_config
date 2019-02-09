#!/bin/bash

#kubectl proxy
#http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

set -x


#Create kube-system cluster permission/rolebinding setup for this user
cat <<EOF > kube-system.admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
EOF

cat <<EOF > kube-system.admin.binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF

#cat <<EOF > kube-system.admin.binding.yaml
#EOF

#Apply this rolebinding as admin
kubectl apply -f kube-system.admin.yaml --kubeconfig /root/.kube/config
kubectl apply -f kube-system.admin.binding.yaml --kubeconfig /root/.kube/config
#kubectl apply -f kubeflow_admin.yaml --kubeconfig /root/.kube/config
kubectl -n kube-system --kubeconfig /root/.kube/config describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') 
