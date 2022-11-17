# Compute instance regional
Allows to create number of compute instances distributed randomly (random_shuffle) among supplied regions.

## Usage example
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
