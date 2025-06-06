.PHONY: help init plan apply destroy fmt validate check output clean import

# Default target
help:
	@echo "Cloudflare Domain Management with Terraform"
	@echo ""
	@echo "Available commands:"
	@echo "  make init      - Initialize Terraform"
	@echo "  make plan      - Show what Terraform will do"
	@echo "  make apply     - Apply the Terraform configuration"
	@echo "  make destroy   - Destroy all managed resources (use with caution!)"
	@echo "  make fmt       - Format Terraform files"
	@echo "  make validate  - Validate Terraform configuration"
	@echo "  make check     - Run fmt and validate"
	@echo "  make output    - Show Terraform outputs"
	@echo "  make clean     - Clean Terraform cache"
	@echo "  make import    - Import existing zone (usage: make import DOMAIN=example.com ZONE_ID=abc123)"
	@echo ""
	@echo "Examples:"
	@echo "  make plan                                    # Preview changes"
	@echo "  make apply                                   # Apply changes"
	@echo "  make import DOMAIN=example.com ZONE_ID=123   # Import existing zone"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	terraform init

# Show what Terraform will do
plan:
	@echo "Planning Terraform changes..."
	terraform plan

# Apply the configuration
apply:
	@echo "Applying Terraform configuration..."
	terraform apply

# Destroy all resources (dangerous!)
destroy:
	@echo "⚠️  WARNING: This will destroy ALL managed resources!"
	@echo "Are you sure? [yes/no]"
	@read confirm && [ "$$confirm" = "yes" ] && terraform destroy || echo "Aborted."

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Validate configuration
validate:
	@echo "Validating Terraform configuration..."
	terraform validate

# Run format and validate
check: fmt validate
	@echo "✅ Format and validation complete"

# Show outputs
output:
	@echo "Current Terraform outputs:"
	terraform output

# Show name servers for all domains
nameservers:
	@echo "Name servers by domain:"
	terraform output -json name_servers_by_domain | jq -r 'to_entries[] | "\(.key): \(.value | join(", "))"'

# Show zone IDs
zones:
	@echo "Zone IDs:"
	terraform output -json zone_ids | jq -r 'to_entries[] | "\(.key): \(.value)"'

# Clean Terraform cache
clean:
	@echo "Cleaning Terraform cache..."
	rm -rf .terraform/
	rm -f .terraform.lock.hcl

# Import existing zone
import:
	@if [ -z "$(DOMAIN)" ] || [ -z "$(ZONE_ID)" ]; then \
		echo "Usage: make import DOMAIN=example.com ZONE_ID=abc123"; \
		exit 1; \
	fi
	@echo "Importing zone $(ZONE_ID) for domain $(DOMAIN)..."
	terraform import 'cloudflare_zone.domains["$(DOMAIN)"]' $(ZONE_ID)

# Refresh state
refresh:
	@echo "Refreshing Terraform state..."
	terraform refresh

# Show state
show:
	@echo "Current Terraform state:"
	terraform show

# List all resources
list:
	@echo "All managed resources:"
	terraform state list

# Generate docs
docs:
	@echo "Terraform configuration overview:"
	@echo ""
	@echo "Domains configured:"
	@yq eval '.domains | keys | .[]' domains.yaml
	@echo ""
	@echo "Total domains: $$(yq eval '.domains | keys | length' domains.yaml)"

# Validate YAML syntax
yaml-check:
	@echo "Validating domains.yaml syntax..."
	@yq eval '.' domains.yaml > /dev/null && echo "✅ YAML syntax is valid" || echo "❌ YAML syntax error"

# Setup for first time use
setup:
	@echo "Setting up Terraform configuration for first time use..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "Creating terraform.tfvars from example..."; \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "⚠️  Please edit terraform.tfvars with your actual values"; \
	else \
		echo "terraform.tfvars already exists"; \
	fi
	@if [ ! -f domains.yaml ]; then \
		echo "❌ domains.yaml not found. Please create it with your domain configuration."; \
	else \
		echo "✅ domains.yaml found"; \
	fi
	@echo ""
	@echo "Next steps:"
	@echo "1. Edit terraform.tfvars with your Cloudflare API token and account name"
	@echo "2. Edit domains.yaml with your domain configuration"
	@echo "3. Run 'make init' to initialize Terraform"
	@echo "4. Run 'make plan' to see what will be created"
	@echo "5. Run 'make apply' to create your domains and DNS records" 