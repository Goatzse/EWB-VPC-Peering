# EWB CLOUD LABS - AWS VPC Peering

## Project 01

This repository contains a Terraform implementation of the EWB Cloud Labs AWS VPC Peering project.

### Architecture

- VPC A: `10.10.0.0/16`
- VPC B: `10.20.0.0/16`
- Public subnet A: `10.10.1.0/24`
- Private subnet A: `10.10.2.0/24`
- Private subnet B: `10.20.1.0/24`
- Bastion: `10.10.1.10` with public IPv4
- App-A: `10.10.2.10` without public IPv4
- App-B: `10.20.1.10` without public IPv4
- VPC peering: `ewb-a-b-peer`

### Repository structure

```text
EWB-VPC-Peering/
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── commands/
│   └── commands.txt
├── screenshots/
└── documentation/
```

### Important

Do not upload:
- `.pem` private keys
- Terraform state files
- passwords
- tokens
- `.tfvars` containing personal secrets

### Terraform deployment

1. Install Terraform and configure AWS credentials.
2. Enter the `terraform` directory.
3. Copy `terraform.tfvars.example` to `terraform.tfvars`.
4. Enter your own student name, public IP `/32`, and SSH public key.
5. Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After deployment, Terraform prints the VPC IDs, peering connection ID, private IPs, and bastion public IP.

### Verification

From App-A:

```bash
ping -c 4 10.20.1.10
```

Expected result after peering and security rules are active: 4 replies with 0% packet loss.

From App-B:

```bash
ping -c 4 10.10.2.10
```

Expected result: 4 replies with 0% packet loss.

The project also requires a controlled ICMP failure test by temporarily removing the App-B ICMP inbound rule from `10.10.2.10/32`, followed by restoring the rule and confirming recovery.

### Source

The architecture and verification requirements follow the provided EWB Cloud Labs AWS VPC Peering Student Project Workbook.
