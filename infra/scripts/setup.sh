#!/bin/bash

script_dir=$(dirname ${BASH_SOURCE[0]})
# Change working directory to gaige2/infrastructure
cd "$script_dir/../"

terraform init
terraform validate
terraform plan -out vm.tfplan

terraform apply vm.tfplan

# Remove the old terraform.env file (optional, depending on your update strategy)
terraform_env_file="../env/.terraform.auto.env"
rm -f $terraform_env_file

