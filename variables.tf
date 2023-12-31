variable "random_postfix_length" {
  type    = string
  default = 16
}

variable "compute_regions" {
  type = list(object({
    name = string
    short = string
    zones = set(string)
  }))
  default = [
        {
            name = "europe-west1"
            short = "ew1"
            zones = ["b", "c", "d"]
        },
        {
            name = "europe-west3"
            short = "ew3"
            zones = ["a", "b", "c"]
        },
        {
            name = "europe-west4"
            short = "ew4"
            zones = ["a", "b", "c"]
        }
    ]
}

variable "env" {
    type = string
}
variable "project" {
    type = string
    default = "gl"
}
variable "custom_subnetworks" {
  type = list(object({
    name = string
    region = string
  }))
  default = []
}
variable "name" {
    type = string
}
variable "domain" {
    type = string
}
variable "labels" {
    type = object({
        app = string
        env = string
        role = optional(string)
        temp = optional(string)
        ingest = optional(string)
        instance = optional(string)
        service = optional(string)
        group = optional(string)
        team = optional(string)
    })
    default = null
}
variable "instance_count" {
    type = number
}
variable "image_os" {
    type = string
    default = "projects/debian-cloud/global/images/debian-11-bullseye-v20221102"
}
variable "machine_type" {
    type = string
}
variable "tags" {
    type = list(string)
}
variable "allow_stopping_for_update" {
    type = bool
    default = true
}
variable "boot_disk_type" {
    type = string
    default = "pd-ssd"
}
variable "boot_disk_size" {
    type = number
    default = 20
}
variable "desired_status" {
    type = string
    default = "RUNNING"
}

variable "need_attached_disk" {
    type = bool
    default = false
}
variable "attached_disks" {
    type = list(object({
        name = string
        type = string
        size = string
    }))
    default = []
}
variable "need_disk_snapshot" {
    type = bool
    default = false
}
variable "disk_snapshot" {
    type = object({
        days_in_cycle = number
        start_time = string
        max_retention_days = number
    })
    default = {
        days_in_cycle = 1
        start_time = "23:00"
        max_retention_days = 14
    }
}
variable "need_external_ip" {
    type = bool
    default = false
}
variable "is_external_ip_static" {
    type = bool
    default = false
}
variable "timeouts" {
    type = object({
        create = optional(string)
        update = optional(string)
        delete = optional(string)
    })
    default = {
        create = "10m"
        update = "10m"
        delete = "10m"
    }
}
variable "shutdown_sleep" {
    type = number
    default = 20
}
variable "shutdown_script_path" {
    type = string
    default = ""
}
variable "use_increment_zone" {
    type = bool
    default = false
}
