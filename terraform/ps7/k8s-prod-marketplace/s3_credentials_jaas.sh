#!/bin/bash

# This is a helper script to set S3 credentials from Vault for JAAS-managed models
# To use it, source it in your shell (`source s3_credentials_jaas.sh`)

export VAULT_ADDR=https://vault.ps7.admin.canonical.com

if ! vault token lookup 1>/dev/null 2>&1; then
    # true if the length of the string is non-zero
    if [ -n "$VAULT_ROLE_ID" ] && [ -n "$VAULT_SECRET_ID" ]; then
        echo "Authenticating to $VAULT_ADDR with AppRole"
        vault write -f -field=token auth/approle/login role_id="$VAULT_ROLE_ID" secret_id="$VAULT_SECRET_ID" | vault login -
    else
        echo "No valid token found, logging in to $VAULT_ADDR with OIDC"
        vault login -method=oidc
    fi
fi

AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key secret/services/k8s-prod-marketplace-default/s3) || return 0
AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_key secret/services/k8s-prod-marketplace-default/s3) || return 0
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
echo "Backend credentials set for k8s-prod-marketplace-default in cloud ps7"
