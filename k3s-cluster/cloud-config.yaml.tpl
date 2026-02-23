#cloud-config
hostname: ${hostname}
package_update: true
packages:
  - qemu-guest-agent
  - netcat-openbsd

users:
  - name: ${vm_user}
    groups: [sudo]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
%{ for key in ssh_public_keys ~}
      - ${key}
%{ endfor ~}

runcmd:
  - systemctl enable --now qemu-guest-agent
%{ if role == "controlplane" ~}
  # --- k3s server (Control Plane) ---
  - |
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" INSTALL_K3S_EXEC="server" sh -s - \
      --flannel-backend=none \
      --disable-network-policy \
      --disable=traefik \
      --disable=servicelb \
      --tls-san=${cp_ip} \
      --cluster-init \
      --write-kubeconfig-mode=600 \
      --token=${k3s_token}
  # k3s server 起動待ち（kubeconfig生成まで最大5分）
  - |
    for i in $(seq 1 60); do
      test -f /etc/rancher/k3s/k3s.yaml && break
      sleep 5
    done
    if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
      echo "ERROR: k3s kubeconfig not found after 5 minutes" >&2
      exit 1
    fi
  # --- Helm install ---
  - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | DESIRED_VERSION="${helm_version}" bash
  # --- Cilium ---
  - |
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    helm repo add cilium https://helm.cilium.io/
    helm install cilium cilium/cilium \
      --namespace kube-system \
      --version ${cilium_version} \
      --set operator.replicas=1 \
      --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" \
      --wait \
      --timeout 300s
  # Cilium 起動待ち（ノードがReadyになるまで最大5分）
  - |
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    for i in $(seq 1 60); do
      kubectl get nodes 2>/dev/null | grep -q " Ready " && break
      sleep 5
    done
    if ! kubectl get nodes 2>/dev/null | grep -q " Ready "; then
      echo "ERROR: Node not Ready after 5 minutes" >&2
      exit 1
    fi
  # --- MetalLB ---
  - |
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    helm repo add metallb https://metallb.universe.tf
    helm install metallb metallb/metallb \
      --namespace metallb-system \
      --create-namespace \
      --wait \
      --timeout 120s
  # MetalLB CRDs Ready 待ち + IPAddressPool/L2Advertisement 適用
  - |
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    for i in $(seq 1 30); do
      kubectl get crd ipaddresspools.metallb.io 2>/dev/null && break
      sleep 5
    done
    if ! kubectl get crd ipaddresspools.metallb.io 2>/dev/null; then
      echo "ERROR: MetalLB CRDs not ready after 2.5 minutes" >&2
      exit 1
    fi
    sleep 10
    cat <<'EOFML' | kubectl apply -f -
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: default-pool
      namespace: metallb-system
    spec:
      addresses:
        - ${metallb_address_range}
    ---
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: default
      namespace: metallb-system
    EOFML
%{ endif ~}
%{ if role == "worker" ~}
  # --- k3s agent (Worker) ---
  # CP の 6443 ポート疎通待ち（最大5分）
  - |
    for i in $(seq 1 60); do
      nc -z ${cp_ip} 6443 && break
      sleep 5
    done
    if ! nc -z ${cp_ip} 6443; then
      echo "ERROR: Control plane port 6443 not reachable after 5 minutes" >&2
      exit 1
    fi
  - |
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" INSTALL_K3S_EXEC="agent" sh -s - \
      --server=https://${cp_ip}:6443 \
      --token=${k3s_token}
%{ endif ~}
