# Infrastructure

## Prerequisites

### Terraform

[install terraform cli](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Azure Login

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
az account show
```

make sure you have the correct subscription selected

## Terraform Init, validate and plan

Make a file called `terraform.tfvars`. Add these variables

1. `resource_prefix = <uniq-name>`, for example your handle like 'joesmith' or
   'janedoe'
2. `azure_subscription_id` = your subscription id, which you can get from
   `az account show`

The `.terraform/` directory (provider binaries) is not committed to Git. You
must run `terraform init` after cloning or pulling to download the required
providers.

All the setup with `terraform` can then be handled with

```bash
./scripts/setup.sh
```

The script runs `terraform init`, `terraform validate`, `terraform plan`, and
`terraform apply` in sequence.

## Remove all resources

```bash
terraform destroy
```
