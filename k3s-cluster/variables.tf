# --- Proxmox接続 ---
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint (例: https://192.168.100.1:8006/)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token (形式: user@realm!tokenid=token-value)"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmoxノード名"
  type        = string
  default     = "home"
}

# --- テンプレート ---
variable "template_vm_id" {
  description = "cloud-initテンプレートのVMID"
  type        = number
  default     = 9000
}

# --- ネットワーク ---
variable "network_bridge" {
  description = "ネットワークブリッジ"
  type        = string
  default     = "vnet1"
}

variable "gateway" {
  description = "デフォルトゲートウェイ"
  type        = string
  default     = "192.168.100.1"
}

variable "dns_servers" {
  description = "DNSサーバー"
  type        = list(string)
  default     = ["8.8.8.8", "1.1.1.1"]
}

# --- k3s VM IP ---
variable "k3s_cp_ip" {
  description = "k3s Control PlaneのIP"
  type        = string
  default     = "192.168.100.101"
}

variable "k3s_worker_ips" {
  description = "k3s WorkerのIPリスト"
  type        = list(string)
  default     = ["192.168.100.102", "192.168.100.103"]
}

# --- VM設定 ---
variable "vm_user" {
  description = "VMのログインユーザー名"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_keys" {
  description = "SSH公開鍵のリスト（鍵の中身を直接指定）"
  type        = list(string)
}

# --- k3s ---
variable "metallb_address_range" {
  description = "MetalLB L2モードで割り当てるIPレンジ"
  type        = string
  default     = "192.168.100.110-192.168.100.120"
}

variable "cilium_version" {
  description = "Cilium Helmチャートのバージョン"
  type        = string
  default     = "1.17.3"
}
