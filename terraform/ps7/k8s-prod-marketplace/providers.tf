locals {
  # Locals used to facilitate local vs CI/CD Terraform operations
  snap_token_path     = "${pathexpand("~")}/snap/vault/current/.vault-token"
  standard_token_path = "${pathexpand("~")}/.vault-token"

  vault_token = var.approle_role_id == null ? (
    fileexists(local.snap_token_path) ? file(local.snap_token_path) : (
      fileexists(local.standard_token_path) ? file(local.standard_token_path) : null
    )
  ) : null

}

provider "vault" {
  address = "https://vault.ps7.admin.canonical.com"
  token   = local.vault_token

  dynamic "auth_login" {
    for_each = var.approle_role_id != null ? [1] : []
    content {
      path = "auth/approle/login"
      parameters = {
        role_id   = var.approle_role_id
        secret_id = var.approle_secret_id
      }
    }
  }
}
ephemeral "vault_kv_secret_v2" "ps7_jaas_credentials" {
  mount = "secret"
  name  = "groups/canonical-webdesign-marketplace/service_account"
}

provider "juju" {
  controller_addresses = "jaas.ps7.canonical.com:443/k8s-jaas-ps7-jimm-jimm"
  client_id            = ephemeral.vault_kv_secret_v2.ps7_jaas_credentials.data["juju_client_id"]
  client_secret        = ephemeral.vault_kv_secret_v2.ps7_jaas_credentials.data["juju_client_secret"]
}
