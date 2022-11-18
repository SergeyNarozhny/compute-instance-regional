# Compute instance regional
Allows to create number of compute instances distributed randomly (random_shuffle) among supplied regions.

## Params
- env ("test", "test-dmz", "common", "common-dmz", "stage", "stage-dmz", "prod", "prod-dmz")
- project ("gl", "eu", "au", "fx") - по умолчанию "gl", но лучше указывать явно
- name - имя сервиса (vault в test-gl-gcpew1b-vault01)
- domain - домен на конце dns (например, test.mx)
- labels - содержимое labels (обязательно указать label "app" и "env")
- image_os - образ для ОС диска (можно не указывать, по умолчанию наливается debian 11)

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
  labels = {
    app = "vault"
    env = "test"
  }
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
  labels = {
    app = "vault"
    env = "test"
  }

  need_attached_disk = true
  attached_disk = {
      name = "vault-storage"
      type = "pd-ssd"
      size = "200"
  }
}
```
### Example 3 with own regions (region object structure must be kept!)
```
module "compute_instance_regional" {
  source = "../../modules/compute-instance-regional"

  compute_regions = [
      {
          name = "europe-west4"
          short = "ew4"
          zones = ["a", "b", "c"]
      },
      {
          name = "europe-west3"
          short = "ew3"
          zones = ["a", "b", "c"]
      },
      {
          name = "europe-west1"
          short = "ew1"
          zones = ["b", "c", "d"]
      },
  ]

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["vault", "to-vault"]
  labels = {
    app = "vault"
    env = "test"
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
