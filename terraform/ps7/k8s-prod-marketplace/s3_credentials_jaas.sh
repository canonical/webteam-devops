#!/bin/bash

# This is a helper script to set S3 credentials from Vault for JAAS-managed models
# To use it, source it in your shell (`source s3_credentials_jaas.sh`)

export VAULT_ADDR=https://vault.ps7.admin.canonical.com

if ! vault token lookup 1>/dev/null 2>&1;
then
    echo "No valid token found, logging in to https://vault.ps7.admin.canonical.com with OIDC"
    vault login -method=oidc
fi

AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key secret/services/k8s-prod-marketplace-default/s3) || return 0
AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_key secret/services/k8s-prod-marketplace-default/s3) || return 0
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
echo "Backend credentials set for k8s-prod-marketplace-default in cloud ps7"