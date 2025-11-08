Terraform modular scaffold

This folder contains a modular Terraform scaffold to deploy an AKS-based environment and deploy applications via Helm. It's intentionally scaffolded with sensible defaults and placeholders so you can adapt it to your subscription and CI/CD flows.

Structure

- modules/
  - network/      -> Resource Group, VNet, Subnet
  - aks/          -> AKS cluster
  - helm-app/     -> Example helm deploy module (uses local-exec helm if desired)
- environments/
  - dev/          -> tfvars for dev
- providers.tf    -> providers and required_providers (placeholder)
- variables.tf    -> top-level variables
- main.tf         -> wires modules together

Notes and next steps

1. This scaffold uses Azure (azurerm) by default. Adjust `providers.tf` if you want AWS/GCP.
2. You will need to provide credentials for the Azure provider (Service Principal or Azure CLI).
3. The `helm-app` module uses a `null_resource` + local-exec by default to avoid complex provider bootstrap. You can replace it with the `helm_release` resource and configure the `kubernetes`/`helm` providers if you prefer a fully managed approach.
4. Fill `environments/dev/terraform.tfvars` with real values before `terraform init`.

If you want, I can also:
- Add a remote backend (azurerm storage) configuration.
- Wire the kubernetes/helm providers so `helm_release` runs inside Terraform.
- Add CI/CD pipeline examples for Azure DevOps or GitHub Actions.
