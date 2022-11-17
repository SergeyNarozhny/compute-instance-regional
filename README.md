# Compute instance regional
Allows to create number of compute instances distributed randomly (random_shuffle) among supplied regions.

## Usage example
### Example 1
```
module "compute_instance_regional" {
  source = "../../modules/compute-instance-regional"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["vault", "to-vault"]
}
```
### Example 2 with disks
```
module "compute_instance_regional" {
  source = "../../modules/compute-instance-regional"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["vault", "to-vault"]

  need_attached_disk = true
  attached_disk = {
      name = "vault-storage"
      type = "pd-ssd"
      size = "200"
  }
}
```

## Outputs
```
- compute_instance_regional.instances
- compute_instance_regional.ids
- compute_instance_regional.instance_ids
- compute_instance_regional.self_links
```
