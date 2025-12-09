## Commands to run

```bash
ssh one@10.0.1.9 #sm08
cd /home/one/one-deploy-validation
source .venv/bin/activate
make I=inventory/sylva/inventory.yaml validation
sudo cp /tmp/cloud_verification_report.html .
sudo cp /tmp/conn-matrix-report.html .
sudo cp /tmp/conn-matrix-raw-data.json .
```