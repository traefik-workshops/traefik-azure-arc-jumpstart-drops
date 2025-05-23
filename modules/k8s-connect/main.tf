variable "context_name" {
  type = string
}

resource "null_resource" "connect" {
  provisioner "local-exec" {
    command = <<EOT
RETRIES=180
SLEEP=10

echo "Waiting up to $((RETRIES * SLEEP / 60)) minutes for kube context '${var.context_name}' and cluster connectivity..."

for i in $(seq 1 $RETRIES); do
  if kubectl config get-contexts --output=name | grep -q "^${var.context_name}$"; then
    echo "Kube context found: ${var.context_name}"

    if kubectl --context=${var.context_name} get nodes > /dev/null 2>&1; then
      echo "Successfully connected to cluster '${var.context_name}'"
      exit 0
    else
      echo "[Attempt $i/$RETRIES] Context found but cluster not reachable yet."
    fi
  else
    echo "[Attempt $i/$RETRIES] Context not available yet."
  fi

  sleep $SLEEP
done

echo "ERROR: Failed to connect to cluster '${var.context_name}' after $((RETRIES * SLEEP / 60)) minutes."
exit 1
EOT
  }
}
