max by (mountpoint) (node_filesystem_avail_bytes{job="node-exporter", instance="$instance", cluster="$cluster", fstype!="", mountpoint!=""})


5368709120