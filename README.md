# Cloudflare Domain Management with Terraform

This repository provides a comprehensive Terraform configuration for managing multiple domains with Cloudflare. It supports DNS records, page rules, and zone settings management through a clean YAML-based configuration.

## Features

- 🌐 **Multi-domain management**: Manage multiple domains from a single configuration
- 📝 **YAML configuration**: Easy-to-read domain configuration in YAML format
- 🔧 **Flexible DNS records**: Support for A, AAAA, CNAME, MX, TXT, and other record types
- 📱 **Page rules**: Configure redirects and other page-level rules
- ⚙️ **Zone settings**: Customize SSL, security, and performance settings per domain
- 🏗️ **Modular structure**: Clean separation of concerns with multiple Terraform files
- 🔒 **Security-focused**: Proper handling of sensitive data and credentials

## Prerequisites

1. **Cloudflare Account**: You need a Cloudflare account with domains added
2. **Cloudflare API Token**: Create an API token with the following permissions:
   - Zone: Edit
   - DNS: Edit
   - Page Rules: Edit
3. **Terraform**: Install Terraform >= 1.0

## Quick Start

### 1. Clone and Setup

```bash
git clone <this-repository>
cd <repository-name>
```

### 2. Configure Cloudflare API Access

Create a `terraform.tfvars` file based on the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add your Cloudflare credentials:

```hcl
cloudflare_api_token = "your_actual_cloudflare_api_token"
cloudflare_account_name = "your_cloudflare_account_name"
```

### 3. Configure Your Domains

Edit the `domains.yaml` file to define your domains. Here's the structure:

```yaml
domains:
  yourdomain.com:
    plan: "free"  # or "pro", "business", "enterprise"
    dns_records:
      - name: "@"
        type: "A"
        value: "192.0.2.1"
        proxied: true
      - name: "www"
        type: "CNAME"
        value: "yourdomain.com"
        proxied: true
      - name: "@"
        type: "MX"
        value: "10 mail.yourdomain.com"
        proxied: false
    page_rules:
      - target: "www.yourdomain.com/*"
        priority: 1
        actions:
          forwarding_url:
            status_code: 301
            url: "https://yourdomain.com/$1"
    zone_settings:
      ssl: "strict"
      security_level: "medium"
```

### 4. Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Plan the changes
terraform plan

# Apply the configuration
terraform apply
```

### 5. Update DNS at Your Registrar

After applying, Terraform will output the name servers for each domain. Update your domain registrar's DNS settings to use these Cloudflare name servers.

```bash
terraform output name_servers_by_domain
```

## Configuration Reference

### Domain Configuration Schema

Each domain in `domains.yaml` supports the following configuration:

#### Basic Settings

```yaml
domains:
  example.com:
    plan: "free"  # Required: "free", "pro", "business", "enterprise"
```

#### DNS Records

```yaml
dns_records:
  - name: "@"           # Required: Record name (@ for root domain)
    type: "A"           # Required: Record type (A, AAAA, CNAME, MX, TXT, etc.)
    value: "1.2.3.4"    # Required: Record value
    proxied: true       # Optional: Enable Cloudflare proxy (default: false)
    ttl: 300           # Optional: TTL in seconds (ignored if proxied=true)
    priority: 10       # Optional: Priority for MX records
```

**Supported DNS Record Types:**
- `A`: IPv4 address
- `AAAA`: IPv6 address
- `CNAME`: Canonical name
- `MX`: Mail exchange
- `TXT`: Text record
- `SRV`: Service record
- `CAA`: Certificate Authority Authorization
- `NS`: Name server

#### Page Rules

```yaml
page_rules:
  - target: "www.example.com/*"     # Required: URL pattern to match
    priority: 1                    # Required: Rule priority (1 = highest)
    actions:
      forwarding_url:              # Redirect to another URL
        status_code: 301           # 301 or 302
        url: "https://example.com/$1"
      cache_level: "standard"      # Cache level setting
      always_use_https: true       # Force HTTPS
```

#### Zone Settings

```yaml
zone_settings:
  ssl: "strict"                    # SSL setting: "off", "flexible", "full", "strict"
  security_level: "medium"         # Security level: "low", "medium", "high", "under_attack"
  automatic_https_rewrites: "on"   # Automatic HTTPS rewrites: "on", "off"
  browser_cache_ttl: 14400        # Browser cache TTL in seconds
  development_mode: "off"          # Development mode: "on", "off"
  min_tls_version: "1.2"          # Minimum TLS version: "1.0", "1.1", "1.2", "1.3"
  # ... more settings available
```

### Default Settings

You can set default zone settings in `terraform.tfvars`:

```hcl
default_zone_settings = {
  ssl                      = "strict"
  automatic_https_rewrites = "on"
  security_level           = "medium"
  # ... more defaults
}
```

Domain-specific settings override these defaults.

## File Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── domains.yaml              # Domain configuration
├── terraform.tfvars.example  # Example variables file
├── terraform.tfvars          # Your actual variables (excluded from git)
├── .gitignore                # Git ignore rules
└── README.md                 # This file
```

## Common Use Cases

### Adding a New Domain

1. Add the domain configuration to `domains.yaml`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to create the zone and records
4. Update your domain registrar to use Cloudflare name servers

### Updating DNS Records

1. Modify the `dns_records` section in `domains.yaml`
2. Run `terraform plan` to see the changes
3. Run `terraform apply` to update the records

### Setting Up Email

```yaml
dns_records:
  - name: "@"
    type: "MX"
    value: "10 mail.yourdomain.com"
    proxied: false
  - name: "@"
    type: "TXT"
    value: "v=spf1 include:_spf.google.com ~all"
    proxied: false
  - name: "mail"
    type: "A"
    value: "192.0.2.10"
    proxied: false
```

### Setting Up Redirects

```yaml
page_rules:
  - target: "www.yourdomain.com/*"
    priority: 1
    actions:
      forwarding_url:
        status_code: 301
        url: "https://yourdomain.com/$1"
```

## Security Best Practices

1. **API Token Security**: Store your Cloudflare API token securely
2. **Terraform State**: Use remote state storage for production
3. **Access Control**: Limit API token permissions to minimum required
4. **Version Control**: Never commit `terraform.tfvars` to version control
5. **SSL Settings**: Use "strict" SSL mode for production domains

## Terraform Commands

```bash
# Initialize Terraform (run once)
terraform init

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List all resources
terraform state list

# Import existing resources (if needed)
terraform import cloudflare_zone.domains[\"example.com\"] zone_id

# Destroy all resources (use with caution!)
terraform destroy
```

## Outputs

After running `terraform apply`, you can view outputs:

```bash
# Show all outputs
terraform output

# Show specific output
terraform output name_servers_by_domain
terraform output zone_ids
```

## Troubleshooting

### Common Issues

1. **Invalid API Token**: Ensure your token has the correct permissions
2. **Zone Already Exists**: If the zone exists in Cloudflare, import it first
3. **DNS Propagation**: DNS changes may take time to propagate globally
4. **Terraform Lock**: If terraform is locked, run `terraform force-unlock LOCK_ID`

### Debugging

Enable debug logging:

```bash
export TF_LOG=DEBUG
terraform apply
```

### Getting Help

1. Check the [Cloudflare Terraform Provider Documentation](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
2. Review Terraform logs for detailed error messages
3. Validate your YAML syntax using an online YAML validator

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues specific to this configuration, please open an issue in this repository. For Cloudflare-specific questions, refer to their official documentation.