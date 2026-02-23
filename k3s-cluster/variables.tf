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

variable "proxmox_insecure" {
  description = "Proxmox APIのTLS証明書検証をスキップする（自己署名証明書用）"
  type        = bool
  default     = false
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

  validation {
    condition     = var.template_vm_id > 0 && var.template_vm_id < 999999999
    error_message = "template_vm_id は正の整数で指定してください。"
  }
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

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.k3s_cp_ip))
    error_message = "k3s_cp_ip は有効なIPv4アドレス形式で指定してください。"
  }
}

variable "k3s_worker_ips" {
  description = "k3s WorkerのIPリスト"
  type        = list(string)
  default     = ["192.168.100.102", "192.168.100.103"]
}

# --- VM スペック ---
variable "vm_cpu_cores" {
  description = "各VMのCPUコア数"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "各VMのメモリ (MB)"
  type        = number
  default     = 4096
}

variable "snippet_datastore_id" {
  description = "cloud-init snippetを保存するProxmoxデータストア"
  type        = string
  default     = "local"
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
variable "k3s_version" {
  description = "k3sのバージョン (例: v1.31.4+k3s1)"
  type        = string
  default     = "v1.31.4+k3s1"

  validation {
    condition     = can(regex("^v\\d+\\.\\d+\\.\\d+\\+k3s\\d+$", var.k3s_version))
    error_message = "k3s_version は v1.31.4+k3s1 の形式で指定してください。"
  }
}

variable "helm_version" {
  description = "Helmのバージョン (例: v3.17.1)"
  type        = string
  default     = "v3.17.1"

  validation {
    condition     = can(regex("^v\\d+\\.\\d+\\.\\d+$", var.helm_version))
    error_message = "helm_version は v3.17.1 の形式で指定してください。"
  }
}

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
