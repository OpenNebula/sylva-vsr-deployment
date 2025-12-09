# Sylva Validation Platform on OpenNebula

## Build VSR chart

```bash
cd chart
tar -czvf vsr-0.2.0.tgz vsr
```

## Deploy VSR

```bash
kubectl create secret docker-registry regcred --docker-server=harbor.rke2-capone-harbor.wclusters.sylva --docker-username=admin --docker-password="<<YOUR_PASS>>" -n vsr-cell-site
kubectl apply -f ./vsr-deployment/nad-passthrough-vf.yaml -n vsr-cell-site
helm install vsr ./chart/vsr-0.2.0.tgz --set day1Config.licenseKey="<<YOUR_LICENSE>>" --values ./vsr-deployment/values.yaml -n vsr-cell-site
```

