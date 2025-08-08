resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  for_each = var.subnets
  name          = "${var.vpc_name}-${each.key}"
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.self_link
  private_ip_google_access = true
  enable_flow_logs = each.value.enable_flow_logs
}

# Router + Cloud NAT for private subnets (one per region)
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  project = var.project_id
  network = google_compute_network.vpc.self_link
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name   = "${var.vpc_name}-nat"
  project = var.project_id
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name = google_compute_subnetwork.subnet["private"].name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Basic firewall: allow internal, SSH from jump hosts, and control plane egress etc.
resource "google_compute_firewall" "allow-internal" {
  name    = "${var.vpc_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.self_link
  allow { protocol = "tcp"; ports = ["0-65535"] }
  allow { protocol = "udp"; ports = ["0-65535"] }
  allow { protocol = "icmp" }
  source_ranges = ["10.0.0.0/8"]
}
