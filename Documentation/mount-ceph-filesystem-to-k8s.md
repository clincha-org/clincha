# Mount Ceph filesystem to Kubernetes

We need to create a CephFS to mount in Ceph. Use the Proxmox interface for this.

![create-cephfs.png](images/create-cephfs.png)

Once that's done login to the host as root

Get the filesystems on the host. E.G "data"
```bash
ceph fs ls
```

Get the subvolumegroup within the filesystem. E.G "downloads"
```bash
ceph fs subvolumegroup ls data
```

These can be created using the instructions of [the documentation](https://github.com/ceph/ceph-csi/blob/devel/docs/static-pvc.md#cephfs-static-pvc).

```bash
ceph fs subvolume ls data downloads
```

To create instead:
```bash
ceph fs subvolume create data complete downloads --size=1073741824
```

Then I need to create a config file for each of the mounts

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-downloads-incomplete
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 1Gi
  csi:
    driver: cephfs.csi.ceph.com
    nodeStageSecretRef:
      # node stage secret name
      name: csi-rbd-secret
      # node stage secret namespace where above secret is created
      namespace: ceph-csi-rbd
    volumeAttributes:
      # Required options from storageclass parameters need to be added in volumeAttributes
      "clusterID": "7c245ed6-0cd9-440e-887b-d9fd402c8470"
      "fsName": "data"
      "staticVolume": "true"
      "rootPath": /volumes/downloads/incomplete/
    # volumeHandle can be anything, need not to be same
    # as PV name or volume name. keeping same for brevity
    volumeHandle: data-downloads-incomplete
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
```