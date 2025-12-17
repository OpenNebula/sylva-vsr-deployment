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

## Deploy VSRs

### Deploy VSR on Cell Site

```bash
kubectl create secret docker-registry regcred --docker-server=harbor.rke2-capone-harbor.wclusters.sylva --docker-username=admin --docker-password="<<YOUR_PASS>>" -n vsr-cell-site
kubectl apply -f ./vsr-deployment/nad-passthrough-vf.yaml -n vsr-cell-site
helm install vsr ./chart/vsr-0.2.0.tgz --set day1Config.licenseKey="<<YOUR_LICENSE>>" --values ./vsr-deployment/values-vsr3.yaml -n vsr-cell-site
```

### Deploy HA VSR on Sec Gw

Deploy the two VSR instances with their specified values. We deploy both of the VSRs in the same namespace to be able to specify a `PodDisruptionBudget`.

```bash
cd vsr-deployment
kubectl create secret docker-registry regcred --docker-server=harbor.rke2-capone-harbor.wclusters.sylva --docker-username=admin --docker-password="<<YOUR_PASS>>" -n vsr1-sec-gw
kubectl apply -f ./vsr-deployment/nad-passthrough-vf.yaml -n vsr1-sec-gw
helm install vsr ./chart/vsr-0.2.0.tgz --set day1Config.licenseKey="<<YOUR_LICENSE>>" --values ./vsr-deployment/values-vsr1.yaml -n vsr1-sec-gw
```

## ISSU 

While traffic is running on the configured IPSec tunnel between the cell-site and sec-gw VSR deployments, we need to perform an upgrade of the sec-gw k8s cluster.

Create a `PodDisruptionBudget`:
```bash
kubectl apply -f ./vsr-deployment/pdb.yaml -n vsr1-sec-gw
```

After editing the `environment-values-capone/workload-clusters/rke2-capone-workload-sec-gw/values.yaml` the `k8s_version` field to the desired value, issue the usual change command:

```bash
cd sylva-core
./apply-workload-cluster.sh ./environment-values/workload-clusters/rke2-capone-workload-sec-gw/  && ./apply.sh ./environment-values/validation-rke2-capone/ 
```

Perform the following steps during the upgrade procedure is going on:
1. Issue `onevm deploy` when the worker VM is created
1. Copy the MLX driver to the worker VM
1. Install the MLX driver as shown above
1. Make sure that the container can be pulled (e.g. /etc/hosts workaround)
1. Verify that the VSR pod can be deployed on the newly created worker VM (e.g. SRIOV resource is created on it)
1. Relax the PDB by editing the `minAvailable` instances from 2 --> 1.
1. Verify that the VSR HA deployment stays operational
