## NOTEs of status as of 19.11.2025:
- only sm08, sm09 and sm10 are added as hosts
- sm10 has 4 NUMA nodes configured
- the GRUB config has not been updated, so the hugepages won't persist
- discovered CAPONE issues:
    - https://github.com/OpenNebula/cluster-api-provider-opennebula/issues/63  
    - https://github.com/OpenNebula/engineering/issues/510
    - sylva-ci has been unstable recently, and ownership is being transfered to Engineering: https://opennebula.slack.com/lists/T02B4EHUK/F07U6M9F0E8?record_id=Rec09SBT4DZ9B
- Here all manual WAs are documented.

## Sylva VM requirements

The control VM where the sylva-core is cloned and all operations are executed from. See more info for other CAPI instructions: https://sylva-projects.gitlab.io/dev-zone/ 
Parameters:
 - Ubuntu 24.04
 - CPU: 2
 - vCPU: 2
 - RAM: 12Gb
 - Disk: 100Gb
Virutal Networks to attach:
 - OpenNebula management network: The VM needs access to the Frontend
 - Management network of the management cluster: it needs to reach its k8s API

## Host configuration

```bash
echo 16384 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
nano /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="hugepagesz=1G hugepages=0 hugepagesz=2M hugepages=4096 default_hugepagesz=2M"
hugetlbfs on /dev/hugepages type hugetlbfs (rw,nosuid,nodev,relatime,pagesize=2M)
```

### SR-IOV

Mostly following this guide: https://docs.opennebula.io/7.0/product/cluster_configuration/hosts_and_clusters/pci_passthrough/  

Some notes, not covered in the docs:
- Reboot, access bios, enable SR-IOV per-NIC
- Configure the NIC driver how many VFs to expose
- Permission problems of “/dev/vfio ” required reboot, until that it did not apply
- probe drivers was cumbersome, not applying immediatly and no error messages/logs

## Validation Platform commands collection

### Kickoff a new Sylva control VM

```bash
git clone git@github.com:OpenNebula/engineering.git
git clone https://gitlab.com/sylva-projects/sylva-core.git
git checkout --track origin/sylva-validation-platform
cd sylva-validation-platform/
./sylva-vm-setup.sh
cp -r environment-values-capone/* /root/sylva-core/environment-values
```

### Deploy k8s clusters

Move the `environment-values-capone` to the sylva-core environment-values, and after bootstrapping the management cluster, deploy the workloads: harbor, cell-site, sec-gw:

```bash
./apply-workload-cluster.sh ./environment-values/workload-clusters/demo-rke2-capone && \
./apply.sh ./environment-values/demo-rke2-capone
```

### Current manual WAs

#### Deploy worker VMs

After the worker VMs has been created, they dont get scheduled because PIN_POLICY=PINNED is missing from the worker (if we add other VMs cant schedule):
```
 onevm deploy 360 3
```

#### Edit supportedNics configmap

The SRIOV opertaror chart does not recognize when only the VF is passed.

Edit `supported-nic-ids` ConfigMap in `cattle-sriov-system` and
Add this line: `Nvidia_mlx5_ConnectX-4LX_VF: 15b3 1016 1016`

Restart these containers:
- cattle-sriov-system/sriov-network-config-daemon-6s4s8
- cattle-sriov-system/operator-webhook-j9nxs

#### Edit /etc/hosts

On each worker VM we have to add the DNS of the Harbor cluster, for example:

```
10.0.1.186 harbor.rke2-capone-harbor.wclusters.sylva
```

### Port forwarding for Sylva services

#### Rancher

```bash
sudo ssh -J root@10.0.1.152 -L 443:10.16.1.253:443 root@10.16.1.2
sudo ssh -L 443:10.0.1.189:443 root@10.0.1.150

# User "sylva-admin" at https://rancher.sylva via OIDC, passwords:
kubectl get secret sylva-units-values  -n sylva-system -o template="{{ .data.values }}" | base64 -d | grep "admin_password:" 

# User "admin" at https://rancher.sylva via local credentials, password:
kubectl   get secret --namespace cattle-system bootstrap-secret   -o go-template='{{.data.bootstrapPassword|base64decode}}{{"\n"}}'
```

#### Harbor

```bash
sudo ssh -L 443:10.0.1.186:443 ubuntu@10.0.1.161  # control plane of harbor cluster

# password for user 'admin' at https://harbor.rke2-capone-harbor.wclusters.sylva/ (set the FQDN in /etc/hosts)
kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get secret harbor-core  -n harbor -o template="{{ .data.HARBOR_ADMIN_PASSWORD }}" | base64 -d
```

### Misc

Install k9s:

```bash
wget https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb && sudo apt install ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb
echo "export PATH=$PATH:/var/lib/rancher/rke2/bin/" >> ~/.bashrc
source ~/.bashrc
k9s --kubeconfig /etc/rancher/rke2/rke2.yaml
```

```bash
sudo echo "127.0.0.1 rancher.sylva flux.sylva keycloak.sylva vault.sylva harbor.sylva thanos.sylva minio-monitoring-tenant-console.sylva" >> /etc/hosts
sudo ssh -J one@10.0.1.35 -L 443:172.20.87.10:80 root@172.20.0.18
curl https://rancher.sylva -H "Host: rancher.sylva" -k
```

### Important k8s objects to look at

Logs:
 - Workload cluster's `cloud-controller-manager`, which is the `opennebula/cloud-provider-opennebula` container
 - Management cluster's `capi-controller-manager`, which is the k8s community's CAPI controller
 - Management cluster's `capone-controller-manager`, which is `opennebula/cluster-api-provider-opennebula` container

 Resources with their statuses and conditions:
 - Management cluster's `ONEMachine` and other `ONE*` 
 - Management cluster's `RKE2` config resources

### Graceful cluster cleanup

Follow the official guide: https://sylva-projects.gitlab.io/docs/1.5/runtime-operations/workload-cluster-operations/removal/ 

### Demo commands

#### Verify Sylva VM prerequisites
```bash
docker --version
pip3 --version
yamllint --version
yq --version
python3 -c "import yaml; print(f'PyYAML version: {yaml.__version__}')"
```

#### Move values files 
```bash
scp -r -o ProxyJump=one@10.0.1.35 demo-rke2-capone/ root@172.20.0.16:/root/sylva-core/environment-values
scp -r -o ProxyJump=one@10.0.1.35 workload-clusters/demo-rke2-capone/ root@172.20.0.16:/root/sylva-core/environment-values/workload-clusters
```

#### sylva-core commands
```bash
./bootstrap.sh ./environment-values/demo-rke2-capone

./apply-workload-cluster.sh ./environment-values/workload-clusters/demo-rke2-capone && \
./apply.sh ./environment-values/demo-rke2-capone && \
./apply-workload-cluster.sh ./environment-values/workload-clusters/demo-rke2-capone
```

#### Verify deployed clusters 
```bash
kubectl get node
kubectl get namespace
kubectl get pod --all-namespaces
```

#### Expose Rancher 
```bash
sudo ssh -J one@10.0.1.35 -L 443:172.20.87.10:443 root@172.20.0.4
kubectl get secret sylva-units-values  -n sylva-system -o template="{{ .data.values }}" | base64 -d | grep admin_password
```

#### Test workload cluster

```bash
kubectl create ns opennebula-demo
kubectl apply -n opennebula-demo -f test.yaml 
kubectl get pods -n opennebula-demo
kubectl logs test-pod-secure -n opennebula-demo
```