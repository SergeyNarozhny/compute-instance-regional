locals {
  instance_regions = [
    for i in range(0, var.instance_count) : {
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
  regions_map = {
    for r in var.compute_regions : r.name => {
      name      = r.name
      short     = r.short
      zones     = r.zones
    }
  }
  instances = {
    for el in local.instance_regions : el.key => {
      key           = el.key
      real_index    = el.key + 1
      region        = el.region.name
      region_short  = el.region.short
      # result[0] because result_count returns 1 el-array
      zone          = var.use_increment_zone ? local.instance_zones[el.key].zones[el.key % length(local.instance_zones[el.key].zones)] : random_shuffle.instances_zones[el.key].result[0]
    }
  }
  disks = flatten([
    for k, inst in google_compute_instance.instances : [
      for disk in var.attached_disks : {
        inst_key  = k
        orig_name = disk.name
        name      = "${disk.name}-${inst.instance_id}"
        key       = "${k}${index(var.attached_disks, disk) + 1}"
        inst_id   = inst.instance_id
        zone      = inst.zone
        region    = regex("\\w+-\\w+", inst.zone)
        type      = disk.type
        size      = disk.size
      }
    ]
  ])
}

# Get subnetworks
data "google_compute_subnetwork" "subnetwork_set" {
  for_each = {
    for region in var.compute_regions : region.short => {
      region  = region.name
      short   = region.short
    }
    if length(var.custom_subnetworks) == 0
  }
  name   = "${var.env}-${each.value.short}"
  region = each.value.region
}
data "google_compute_subnetwork" "custom_subnetworks" {
  for_each = {
    for subnet in var.custom_subnetworks : subnet.region => {
      subnet  = subnet.name
      region  = subnet.region
      short   = local.regions_map[subnet.region].short
    }
  }
  name   = each.value.subnet
  region = each.value.region
}

# Generate random zone for each node
resource "random_shuffle" "instances_zones" {
  for_each      = local.instance_zones
  input         = each.value.zones
  result_count  = 1
}

# Attached disks
resource "google_compute_disk" "nodes_disk" {
  for_each = {
      for disk in local.disks : disk.key => disk
      if var.need_attached_disk
  }
  name = each.value.name
  zone = each.value.zone
  type = each.value.type
  size = each.value.size
}
resource "google_compute_attached_disk" "nodes_disk_attachment" {
  for_each = {
      for disk in local.disks : disk.key => disk
      if var.need_attached_disk
  }
  disk        = google_compute_disk.nodes_disk[each.value.key].self_link
  instance    = google_compute_instance.instances[each.value.inst_key].self_link
  device_name = each.value.orig_name
}
# Snapshots for attached disks
resource "google_compute_resource_policy" "disks_snapshot" {
  for_each = {
      for disk in local.disks : disk.key => disk
      if var.need_attached_disk && var.need_disk_snapshot
  }
  name   = "${google_compute_disk.nodes_disk[each.value.key].name}-policy"
  region = each.value.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle     = var.disk_snapshot.days_in_cycle
        start_time        = var.disk_snapshot.start_time
      }
    }
    retention_policy {
      max_retention_days  = var.disk_snapshot.max_retention_days
    }
  }
}
resource "google_compute_disk_resource_policy_attachment" "snapshots_attachment" {
  for_each = {
      for disk in local.disks : disk.key => disk
      if var.need_attached_disk && var.need_disk_snapshot
  }
  name = google_compute_resource_policy.disks_snapshot[each.value.key].name
  disk = google_compute_disk.nodes_disk[each.value.key].name
  zone = each.value.zone
}

# BOOT disks
resource "google_compute_disk" "boot_disks" {
  for_each = {
      for inst in local.instances : inst.key => inst
  }
  name    = "bootdisk-${var.env}-${var.project}-gcp${each.value.region_short}${each.value.zone}-${var.name}${format("%.2d", each.value.real_index)}"
  zone    = "${each.value.region}-${each.value.zone}"
  image   = var.image_os
  type    = var.boot_disk_type
  size    = var.boot_disk_size
}
# Snapshots for boot disks
resource "google_compute_resource_policy" "boot_disks_snapshot" {
  for_each = {
      for inst in local.instances : inst.key => inst
      if var.need_disk_snapshot
  }
  name   = "${google_compute_disk.boot_disks[each.value.key].name}-policy"
  region = each.value.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle     = var.disk_snapshot.days_in_cycle
        start_time        = var.disk_snapshot.start_time
      }
    }
    retention_policy {
      max_retention_days    = var.disk_snapshot.max_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}
resource "google_compute_disk_resource_policy_attachment" "boot_snapshots_attachment" {
  for_each = {
      for inst in local.instances : inst.key => inst
      if var.need_disk_snapshot
  }
  name = google_compute_resource_policy.boot_disks_snapshot[each.value.key].name
  disk = google_compute_disk.boot_disks[each.value.key].name
  zone = "${each.value.region}-${each.value.zone}"
}

# INSTANCES
resource "google_compute_instance" "instances" {
  for_each = {
    for inst in local.instances : inst.key => inst
  }
  name                      = "${var.env}-${var.project}-gcp${each.value.region_short}${each.value.zone}-${var.name}${format("%.2d", each.value.real_index)}"
  hostname                  = "${var.env}-${var.project}-gcp${each.value.region_short}${each.value.zone}-${var.name}${format("%.2d", each.value.real_index)}.${var.domain}"
  zone                      = "${each.value.region}-${each.value.zone}"

  machine_type              = var.machine_type
  tags                      = var.tags
  allow_stopping_for_update = var.allow_stopping_for_update

  boot_disk {
    source = google_compute_disk.boot_disks[each.value.key].self_link
  }

  network_interface {
    subnetwork = length(var.custom_subnetworks) == 0 ? data.google_compute_subnetwork.subnetwork_set[each.value.region_short].self_link : data.google_compute_subnetwork.custom_subnetworks[each.value.region].self_link

    dynamic access_config {
      for_each = var.need_external_ip ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  labels = merge(var.labels, {
    instance_number = each.value.real_index
  })

  lifecycle {
    ignore_changes = [attached_disk]
  }

  metadata = {
    serial-port-enable = true
    shutdown-script = var.shutdown_script_path != "" ? file("${path.cwd}/${var.shutdown_script_path}") : "#! /bin/bash sleep ${each.key * var.shutdown_sleep}"
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
