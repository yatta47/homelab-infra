terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.96"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true # 自己署名証明書

  ssh {
    agent    = true
    username = "root"
  }
}

# --- k3s join token ---
resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

# --- VM定義をまとめる ---
locals {
  nodes = merge(
    {
      "k3s-cp1" = {
        ip   = var.k3s_cp_ip
        role = "controlplane"
      }
    },
    {
      for i, ip in var.k3s_worker_ips : "k3s-wk${i + 1}" => {
        ip   = ip
        role = "worker"
      }
    }
  )
}

# --- cloud-init user_data (VM毎に生成) ---
resource "proxmox_virtual_environment_file" "cloud_config" {
  for_each     = local.nodes
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-config.yaml.tpl", {
      hostname              = each.key
      vm_user               = var.vm_user
      ssh_public_keys       = var.ssh_public_keys
      role                  = each.value.role
      cp_ip                 = var.k3s_cp_ip
      k3s_token             = random_password.k3s_token.result
      metallb_address_range = var.metallb_address_range
      cilium_version        = var.cilium_version
    })

    file_name = "${each.key}-cloud-config.yaml"
  }
}

# --- k3s VMs ---
resource "proxmox_virtual_environment_vm" "k3s" {
  for_each  = local.nodes
  name      = each.key
  node_name = var.proxmox_node

  clone {
    vm_id = var.template_vm_id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.gateway
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config[each.key].id
    dns {
      servers = var.dns_servers
    }
  }

  stop_on_destroy = true
}
