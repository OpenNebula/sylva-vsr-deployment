# Sylva Validation Platform on OpenNebula

## Build VSR chart

```bash
cd chart
tar -czvf vsr-0.2.0.tgz vsr
```

## Prerequisites

### Harbor image load/push

```bash
docker load --input 6wind-vsr-v3.10.tar
docker tag download.6wind.com/vsr/x86_64-ce/3.10:3.10.1.3 harbor.rke2-capone-harbor.wclusters.sylva/library/vsr:3.10.1.3
docker push harbor.rke2-capone-harbor.wclusters.sylva/library/vsr:3.10.1.3
```

### Worker driver prereqs

On the used ootb Ubuntu, we need to follow the steps for the DPDK prerequisites on Mellanox NICs: https://doc.dpdk.org/guides-23.07/platform/mlx5.html  

In total this is:

```bash
tar -xvf MLNX_OFED_LINUX-24.10-3.2.5.0-ubuntu22.04-x86_64.tgz
cd MLNX_OFED_LINUX-24.10-3.2.5.0-ubuntu22.04-x86_64/
sudo ./mlnxofedinstall --dpdk
sudo /etc/init.d/openibd restart
sudo reboot
```

### Manual networking config

Configure on the host the VF to have the correct VLAN tagged on it for that VF that is passed to the container.

```
sudo ip link set enp129s0f0np0 vf 0 vlan 2003 trust on
```

## Deploy VSR

```bash
kubectl create secret docker-registry regcred --docker-server=harbor.rke2-capone-harbor.wclusters.sylva --docker-username=admin --docker-password="<<YOUR_PASS>>" -n vsr-cell-site
kubectl apply -f ./vsr-deployment/nad-passthrough-vf.yaml -n vsr-cell-site
helm install vsr ./chart/vsr-0.2.0.tgz --set day1Config.licenseKey="<<YOUR_LICENSE>>" --values ./vsr-deployment/values.yaml -n vsr-cell-site
```

## ISSU 

While traffic is running on the configured IPSec tunnel between the cell-site and sec-gw VSR deployments, we need to perform an upgrade of the sec-gw k8s cluster.

After editing the `environment-values-capone/workload-clusters/rke2-capone-workload-sec-gw/values.yaml` the `k8s_version` field to the desired value, issue the usual change command:

```bash
cd sylva-core
./apply-workload-cluster.sh ./environment-values/workload-clusters/rke2-capone-workload-sec-gw/  && ./apply.sh ./environment-values/validation-rke2-capone/ 
```
