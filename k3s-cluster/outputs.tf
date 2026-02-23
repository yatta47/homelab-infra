output "k3s_nodes" {
  description = "k3s全ノードの名前とIP"
  value = {
    for name, node in local.nodes : name => {
      ip   = node.ip
      role = node.role
    }
  }
}

output "ssh_commands" {
  description = "各ノードへのSSHコマンド"
  value = {
    for name, node in local.nodes : name => "ssh ${var.vm_user}@${node.ip}"
  }
}

output "kubeconfig_commands" {
  description = "ローカルにkubeconfigを取得するコマンド"
  value       = <<-EOT
    # kubeconfig を取得
    scp ${var.vm_user}@${var.k3s_cp_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config
    sed -i 's/127.0.0.1/${var.k3s_cp_ip}/' ~/.kube/k3s-config
    export KUBECONFIG=~/.kube/k3s-config
    kubectl get nodes
  EOT
}

output "k3s_token" {
  description = "k3s join token（デバッグ用）"
  value       = random_password.k3s_token.result
  sensitive   = true
}
