locals {
  env = var.env
  project = var.project
  name = var.name
  domain = var.domain
  label_app = var.label_app
  label_role = var.label_role
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

# DISKS with attachments
resource "google_compute_disk" "nodes_disk" {
  for_each = {
      for el in local.instance_regions : el.key => {
          region    = el.region.name
          zone      = random_shuffle.instances_zones[el.key].result[0] # 0 because result_count returns 1 el-array
      }
      if var.need_attached_disk
  }
  name = var.attached_disk.name
  type = var.attached_disk.type
  zone = "${each.value.region}-${each.value.zone}"
  size = var.attached_disk.size
}
resource "google_compute_attached_disk" "disks_attachment" {
  for_each = {
      for el in local.instance_regions : el.key => {
          key       = el.key
          region    = el.region.name
          zone      = random_shuffle.instances_zones[el.key].result[0] # 0 because result_count returns 1 el-array
      }
      if var.need_attached_disk
  }
  disk     = google_compute_disk.nodes_disk[each.value.key].self_link
  instance = google_compute_instance.instances[each.value.key].self_link
}

# INSTANCES
resource "google_compute_instance" "instances" {
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
    app = local.label_app
    env = local.env
    role = local.label_role
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }
}
