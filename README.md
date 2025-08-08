# Google Cloud VPC Terraform Module

This Terraform module provisions a **production-ready Virtual Private Cloud (VPC)** environment on Google Cloud Platform (GCP), complete with subnets, Cloud NAT, routers, and firewall rules.

---

## 📁 Directory Structure

```text
terraform-google-modules/terraform-google-vpc/
├── .gitignore
├── main.tf
├── outputs.tf
├── README.md
└── variables.tf
```

---

## 🚀 Features

- Custom VPC network (non-auto)
- Multiple custom subnets with CIDR ranges and flow logs
- Cloud Router and Cloud NAT for internet access in private subnets
- Internal communication firewall rule
- Output references for network and subnets

---

## 📦 Usage

```hcl
module "vpc" {
  source     = "./modules/vpc"
  project_id = "your-gcp-project-id"
  region     = "us-central1"
  vpc_name   = "prod-vpc"

  subnets = {
    private = {
      cidr             = "10.10.1.0/24"
      region           = "us-central1"
      enable_flow_logs = true
    },
    public = {
      cidr             = "10.10.2.0/24"
      region           = "us-central1"
      enable_flow_logs = false
    }
  }
}
```

---

## 🧩 Inputs

| Name        | Type                                                                 | Description                                             | Required |
|-------------|----------------------------------------------------------------------|---------------------------------------------------------|----------|
| project_id  | `string`                                                             | The GCP project ID where the resources will be created. | ✅ Yes   |
| region      | `string`                                                             | Default region for resources like NAT router.           | ✅ Yes   |
| vpc_name    | `string`                                                             | The name of the VPC to create.                          | ✅ Yes   |
| subnets     | `map(object({cidr=string, region=string, enable_flow_logs=bool}))`   | Map of subnet names to definitions.                     | ✅ Yes   |

---

## 📤 Outputs

| Name              | Description                                         |
|-------------------|-----------------------------------------------------|
| `vpc_self_link`   | The self-link URI of the created VPC network.       |
| `subnet_self_links` | A map of subnet names to their self-link URIs.    |

---

## 🏗️ Resources Created

### VPC Network

```hcl
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}
```

- Creates a custom mode VPC to control your own subnets.
- `auto_create_subnetworks = false` disables auto-mode.

---

### Subnets

```hcl
resource "google_compute_subnetwork" "subnet" {
  for_each = var.subnets
  name                    = "${var.vpc_name}-${each.key}"
  ip_cidr_range           = each.value.cidr
  region                  = each.value.region
  network                 = google_compute_network.vpc.self_link
  private_ip_google_access = true
  enable_flow_logs        = each.value.enable_flow_logs
}
```

- Creates one subnet per key in the `subnets` map.
- Enables private Google access (`private_ip_google_access = true`) for APIs like GKE.

---

### Cloud Router and Cloud NAT

```hcl
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  project = var.project_id
  network = google_compute_network.vpc.self_link
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.subnet["private"].name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
```

- Allows private subnets to reach the internet (for GKE nodes, image pulling, OS updates).
- Automatically assigns IPs for NAT.

---

### Firewall Rules

```hcl
resource "google_compute_firewall" "allow-internal" {
  name    = "${var.vpc_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}
```

- Allows internal communication between VMs and services in the 10.0.0.0/8 CIDR range.

---

## 🛡️ Production Considerations

- Add a firewall rule to restrict SSH to bastion/jump host IP ranges.
- Set up additional firewall rules for app/service-specific access.
- Consider enabling VPC Service Controls for sensitive workloads.
- For subnet isolation, use multiple VPCs + VPC peering.

---

## 📚 References

- [Google Cloud VPC Docs](https://cloud.google.com/vpc/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Cloud NAT Docs](https://cloud.google.com/nat/docs)

---

## ✍️ Author & Maintainer

Created and maintained by **Ahmed Osama Taha**  
📧 Email: [ahmed.osama.taha2@gmail.com](mailto:ahmed.osama.taha2@gmail.com)  
🔗 LinkedIn: [linkedin.com/in/ahmedosamataha](https://www.linkedin.com/in/ahmedosamataha)

---

## 🪪 License

MIT License — feel free to fork and contribute!

