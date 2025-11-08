variable "name" {}

resource "null_resource" "deploy" {
  triggers = {
    name      = var.name
    chart     = var.chart
    namespace = var.namespace
  }

  provisioner "local-exec" {
    command = <<EOT
mkdir -p /tmp/helm-deploy
export KUBECONFIG="/tmp/${var.name}-kubeconfig"
cat > /tmp/${var.name}-kubeconfig <<'KCFG'
${var.kubeconfig}
KCFG

helm upgrade --install ${var.name} ${var.chart} --namespace ${var.namespace} --create-namespace
EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

output "release_name" {
  value = var.name
}
