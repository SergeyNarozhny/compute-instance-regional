locals {
  env = var.env
  project = var.project
  name = var.name
  domain = var.domain
  instance_count = var.instance_count

  image_os = var.image_os
  instance_regions = [
    for i in range(0, local.instance_count) : {
      key       = i
      index     = i % length(var.compute_regions)
      region    = element(var.compute_regions, i % length(var.compute_regions))
    }
  ]
  instance_zones = {
    for el in local.instance_regions : el.key => {
      zones     = sort(el.region.zones)
    }
  }
}

# Get subnetworks
data "google_compute_subnetwork" "subnetwork_set" {
  for_each = {
    for region in var.compute_regions : region.short => {
      region  = region.name
      short   = region.short
    }
  }
  name   = "${local.env}-${each.value.short}"
  region = each.value.region
}

# Generate random zone for each node
resource "random_shuffle" "instances_zones" {
  for_each      = local.instance_zones
  input         = each.value.zones
  result_count  = 1
}

# VAULT nodes
resource "google_compute_instance" "vault_instances" {
  for_each = {
    for el in local.instance_regions : el.key => {
      region        = el.region.name
      region_short  = el.region.short
      zone          = random_shuffle.instances_zones[el.key].result[0] # 0 because result_count returns 1 el-array
    }
  }
  name                      = "${local.env}-${local.project}-gcp${each.value.region_short}${each.value.zone}-${local.name}${format("%.2d", each.key + 1)}"
  hostname                  = "${local.env}-${local.project}-gcp${each.value.region_short}${each.value.zone}-${local.name}${format("%.2d", each.key + 1)}.${local.domain}"
  zone                      = "${each.value.region}-${each.value.zone}"

  machine_type              = var.machine_type
  tags                      = var.tags
  allow_stopping_for_update = var.allow_stopping_for_update

  boot_disk {
    initialize_params {
      image = local.image_os
      type = var.boot_disk_type
      size = var.boot_disk_size
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnetwork_set[each.value.region_short].self_link
  }

  labels = {
    app = local.name
    env = local.env
  }
}
