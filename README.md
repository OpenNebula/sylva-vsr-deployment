# Sylva Validation Platform with OpenNebula

The goal of this repo is to document the artefacts needed to build a Sylva Validation Platfrom on OpenNebula virtual infrastructure and perform a reference CNF certification.

## Sylva Infrastructure Deployment

The infrastructure deployment consists of these high-level steps:
1. OpenNebula is deployed 
1. Sylva Control VM is created
1. Sylva Management Cluster is deployed
1. Harbor cluster is deployed as a Sylva workload
1. Workload clusters are deployed to host CNFs

The details are here: [Sylva Infrastructure Deployment Documentation](./sylva-validation-platform/README.md)

## CNF Deployment and ISSU

To deploy an example workload, specifically 6Wind Virtual Service Routers, follow the documentation here: [6Wind VSR Deployment Documentation](./vsr-deployment/README.md).

