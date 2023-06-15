#!/bin/bash

helm repo add ceph-csi https://ceph.github.io/csi-charts

git clone https://github.com/ceph/ceph-csi.git

cd ceph-csi/charts/ || exit

kubectl create namespace "ceph-csi-rbd"

helm install -f ceph-csi-rbd-values.yml --namespace "ceph-csi-rbd" "ceph-csi-rbd" ceph-csi/ceph-csi-rbd

helm status --namespace "ceph-csi-rbd" "ceph-csi-rbd"

k get all -n ceph-csi-rbd
