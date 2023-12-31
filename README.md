# Compute instance regional
Allows to create number of compute instances distributed randomly (random_shuffle) among supplied regions.

## Params
- compute_regions (по-умолчанию = регионы EU) - массив объектов регионов с заданными параметрами
- env ("test", "test-dmz", "common", "common-dmz", "stage", "stage-dmz", "prod", "prod-dmz")
- project ("gl", "eu", "au", "fx") - по умолчанию "gl", но лучше указывать явно
- custom_subnetwork (опционально) - кастомный subnetwork для деплоя VM в случае переопределения compute_regions
- name - имя сервиса (vault в test-gl-gcpew1b-vault01)
- domain - домен на конце dns (например, test.mx)
- labels - содержимое labels (обязательно указать label "app" и "env")
  label "instance_number" зарезервирован и проставляется автоматически = порядковый номер наливаемой VM
- image_os - образ для ОС диска (можно не указывать, по умолчанию наливается debian 11)
- need_attached_disk - true для подключения дополнительного диска к каждой машине
- attached_disks - параметры дополнительно подключаемых дисков
- need_disk_snapshot - true для регулярного бэкапирования диска
- need_external_ip (опционально, по-умолчанию false) - зарегать ephemeral external ip для тачки
- is_external_ip_static (опционально, по-умолчанию false) - зарегать статический ip в качестве external (вместо ephemeral), используется совместно с включенной need_external_ip
- disk_snapshot - параметры для бэкапирования дополнительно подключаемого диска (по умолчанию days_in_cycle = 1, start_time = "23:00", max_retention_days = 14)
- timeouts (create, update, delete = "10m") - таймауты на операции инстанса (создание, обновление, удаление)
- shutdown_sleep (по-умолчанию = 20) - время в cекундах, которое используется как множитель для команды sleep при любой перезагрузке/выключении VM
- desired_status (по-умолчанию "RUNNING") - желаемое состояние инстансов после terraform apply
- shutdown_script_path - путь до shutdown-скрипта (опционально, от корня tf плана)
- use_increment_zone - true для последовательного выбора зон согласно индексу VM (вместо random shuffle функции)

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
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }
}
```
### Example 2 with disk and custom timeouts
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }

  need_attached_disk = true
  attached_disks = [{
      name = "vault-storage"
      type = "pd-ssd"
      size = "200"
  }]

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
      }
  ]

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }

  shutdown_script_path = "scripts/shutdown.sh"
}
```
### Example 4 with disk and backup snapshots
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }

  need_attached_disk = true
  need_disk_snapshot = true
  attached_disks = [{
      name = "vault-storage"
      type = "pd-ssd"
      size = "200"
  }]
}
```
### Example 5 with disk and backup snapshots on custom schedule (each day during 14 days executed on 23:00)
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }

  need_attached_disk = true
  need_disk_snapshot = true
  attached_disks = [{
      name = "vault-storage"
      type = "pd-ssd"
      size = "200"
  }]
  disk_snapshot = {
      days_in_cycle = 1
      start_time = "23:00"
      max_retention_days = 14
  }
}
```
### Example 6 with custom_subnetwork and diff compute_regions
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

  custom_subnetworks = [
      {
          name = "fx-prod-net01"
          region = "asia-southeast2"
      }
  ]
  compute_regions = [
      {
          name = "asia-southeast2"
          short = "as2"
          zones = ["a", "b", "c"]
      }
  ]

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }
}
```
### Example 7 with use_increment_zone
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }

  use_increment_zone = true
}
```
### Example 8 with several disks
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
  labels = {
    app = "vault"
    env = "test"
  }

  need_attached_disk = true
  attached_disks = [{
      name = "vault-storage"
      type = "pd-ssd"
      size = "50"
  }, {
      name = "os-storage"
      type = "pd-ssd"
      size = "100"
  }]
}
```
### Example 9 with external static ip
```
module "compute_instance_regional" {
  source = "git@gitlab.fbs-d.com:terraform/modules/compute-instance-regional.git"

  env = "test"
  project = "gl"
  name = "vault"
  domain = "test.mx"
  instance_count = 3
  need_external_ip = true
  is_external_ip_static = true

  machine_type = "e2-highcpu-2"
  tags = ["test-vault"]
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
- compute_instance_regional.vm_ips
- compute_instance_regional.vm_nat_ips
```
