# PS7 Demos

Terraform configuration to deploy a PS7-like environment with 2 example demos applications
locally in a Multipass VM.

To be able to use this you should have installed the 
[webteam-juju-dev-provisioning](https://github.com/alvaromateo/webteam-juju-dev-provisioning/tree/ingress)
(switch to the 'ingress' branch to make sure you have the latest changes before installing) and
launched a Multipass VM from the root of this project (where the `juju_local.yaml` file is).

## How to deploy

SSH into the Multipass VM and go into this project's `terraform/local-ps7` directory.

```bash
terraform init
terraform apply -auto-approve
```

The full PS7 local environment will be deployed in Multipass' VM.

## Access the app from your host browser

The app is served by HAProxy, which runs in an LXD container inside the VM on a
network your host cannot reach directly, and it routes by `Host` header (e.g.
`app.local`). Terraform discovers the VM IP and the HAProxy IP and exposes them
as outputs; two small wrappers apply them.

Check the discovered values (optional):

```bash
terraform output          # vm_ip, haproxy_ip, hostnames, ...
```

### 1. In the VM — forward the VM's ports to HAProxy

```bash
sudo configure-ingress-forwarding
```

This reads the Terraform outputs and installs a static nftables DNAT rule
(`VM_IP:80,443 -> HAPROXY_IP`), persisted across reboots via a systemd oneshot
unit. Tear it down with `--remove`.

### 2. On your host laptop — resolve the hostname

```bash
sudo .ingress_hosts_sync.sh <vm-name>   # e.g. test-ingress
container_ca_trust <vm-name>            # set up certs to make SSO work
```

This writes a managed block into your `/etc/hosts` mapping the ingress
hostnames to the VM. Works on Linux and macOS; only needs `multipass`. Remove
it with `--remove`.

Then you can open any of the demos in your browser.

> Note: the nftables rule uses the HAProxy IP as discovered at `apply` time. If
> HAProxy is redeployed and its IP changes, re-run `terraform apply` followed by
> step 1 (and step 2 if the VM IP changed).

### Clean up

You can remove the certificates added to your browser by running:

```bash
container_ca_trust <vm-name> --delete
```
