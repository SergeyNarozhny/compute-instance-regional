# Compute instance regional
Allows to create number of compute instances distributed randomly (random_shuffle) among supplied regions.

## Params
- env ("test", "test-dmz", "common", "common-dmz", "stage", "stage-dmz", "prod", "prod-dmz")
- project ("gl", "eu", "au", "fx") - по умолчанию "gl", но лучше указывать явно
- name - имя сервиса (vault в test-gl-gcpew1b-vault01)
- domain - домен на конце dns (например, test.mx)
- labels - содержимое labels (обязательно указать label "app" и "env")
- image_os - образ для ОС диска (можно не указывать, по умолчанию наливается debian 11)
- need_attached_disk - true для подключения дополнительного диска к каждой машине
- attached_disk - параметры дополнительно подключаемого диска
- need_disk_snapshot - true для регулярного бэкапирования диска
- disk_snapshot - параметры для бэкапирования дополнительно подключаемого диска (по умолчанию days_in_cycle = 1, start_time = "23:00", max_retention_days = 14)
- timeouts (create, update, delete = "10m") - таймауты на операции инстанса (создание, обновление, удаление)
- shutdown_script_path - путь до shutdown-скрипта (опционально, от корня tf плана)

## Usage example
### Example 1
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

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
### Example 2 with disks and custom timeouts
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

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

  timeouts = {
      create = "1m"
      update = "1m"
      delete = "30s"
  }
}
```
### Example 3 with own regions (region object structure must be kept!) and shutdown script
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

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

  shutdown_script_path = "scripts/shutdown.sh"
}
```
### Example 4 with disks and backup snapshots
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

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
  need_disk_snapshot = true
  attached_disk = {
      name = "vault-storage"
      type = "pd-ssd"
      size = "200"
  }
}
```
### Example 5 with disks and backup snapshots on custom schedule (once in 3 days with 9 days retention executed on 00:00)
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

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
  need_disk_snapshot = true
  attached_disk = {
      name = "vault-storage"
      type = "pd-ssd"
      size = "200"
  }
  disk_snapshot = {
      days_in_cycle = 3
      start_time = "00:00"
      max_retention_days = 9
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
