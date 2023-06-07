output "instances" {
    value = google_compute_instance.instances
}
output "ids" {
    value = values(google_compute_instance.instances)[*].id
}
output "instance_ids" {
    value = values(google_compute_instance.instances)[*].instance_id
}
output "self_links" {
    value = values(google_compute_instance.instances)[*].self_link
}
output "vm_ips" {
    value = values(google_compute_instance.instances)[*].network_interface.0.network_ip
}
