# main.tf
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure the Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Data source to get account ID
data "cloudflare_accounts" "main" {
  name = var.cloudflare_account_name
}

# Load domains configuration from YAML file
locals {
  domains_config = yamldecode(file(var.domains_config_file))
  domains        = local.domains_config.domains

  # Flatten DNS records for easy iteration
  dns_records = flatten([
    for domain, config in local.domains : [
      for dns_record in config.dns_records : {
        key      = "${domain}-${dns_record.name}-${dns_record.type}-${substr(sha256("${dns_record.value}"), 0, 8)}"
        domain   = domain
        name     = dns_record.name
        type     = dns_record.type
        value    = dns_record.value
        proxied  = lookup(dns_record, "proxied", false)
        ttl      = lookup(dns_record, "ttl", 1)
        priority = lookup(dns_record, "priority", null)
      }
    ]
  ])

  # Flatten page rules for easy iteration
  page_rules = flatten([
    for domain, config in local.domains : [
      for idx, page_rule in lookup(config, "page_rules", []) : {
        key      = "${domain}-rule-${idx}"
        domain   = domain
        target   = page_rule.target
        priority = page_rule.priority
        actions  = page_rule.actions
      }
    ]
  ])

  # Flatten firewall rules for easy iteration
  firewall_rules = flatten([
    for domain, config in local.domains : [
      for idx, firewall_rule in lookup(config, "firewall_rules", []) : {
        key         = "${domain}-firewall-${idx}"
        domain      = domain
        description = firewall_rule.description
        expression  = firewall_rule.expression
        action      = firewall_rule.action
        priority    = lookup(firewall_rule, "priority", 1)
        enabled     = lookup(firewall_rule, "enabled", true)
      }
    ]
  ])

  # Flatten rate limiting rules
  rate_limit_rules = flatten([
    for domain, config in local.domains : [
      for idx, rate_rule in lookup(config, "rate_limit_rules", []) : {
        key                 = "${domain}-ratelimit-${idx}"
        domain              = domain
        description         = rate_rule.description
        expression          = rate_rule.expression
        action              = rate_rule.action
        characteristics     = lookup(rate_rule, "characteristics", ["cf.colo.id", "ip.src"])
        period              = lookup(rate_rule, "period", 60)
        requests_per_period = lookup(rate_rule, "requests_per_period", 100)
        enabled             = lookup(rate_rule, "enabled", true)
      }
    ]
  ])
}

# Create zones for each domain
resource "cloudflare_zone" "domains" {
  for_each   = local.domains
  zone       = each.key
  account_id = data.cloudflare_accounts.main.accounts[0].id
  plan       = lookup(each.value, "plan", "free")
}

# Enable DNSSEC for each domain (free security feature)
resource "cloudflare_zone_dnssec" "dnssec" {
  for_each = local.domains
  zone_id  = cloudflare_zone.domains[each.key].id
}

# Create DNS records for each domain
resource "cloudflare_record" "dns_records" {
  for_each = {
    for record in local.dns_records : record.key => record
  }

  zone_id  = cloudflare_zone.domains[each.value.domain].id
  name     = each.value.name
  type     = each.value.type
  value    = each.value.value
  proxied  = each.value.proxied
  ttl      = each.value.proxied ? 1 : each.value.ttl
  priority = each.value.priority

  # Allow external changes (useful for some automated DNS updates)
  lifecycle {
    ignore_changes = [
      # Uncomment the line below if you want to ignore external changes to DNS records
      # value,
    ]
  }
}

# Create page rules for each domain
resource "cloudflare_page_rule" "page_rules" {
  for_each = {
    for rule in local.page_rules : rule.key => rule
  }

  zone_id  = cloudflare_zone.domains[each.value.domain].id
  target   = each.value.target
  priority = each.value.priority

  actions {
    dynamic "forwarding_url" {
      for_each = lookup(each.value.actions, "forwarding_url", null) != null ? [each.value.actions.forwarding_url] : []
      content {
        status_code = forwarding_url.value.status_code
        url         = forwarding_url.value.url
      }
    }

    # Page rule actions
    cache_level = lookup(each.value.actions, "cache_level", null)
    always_use_https = lookup(each.value.actions, "always_use_https", null)
    security_level = lookup(each.value.actions, "security_level", null)
    browser_check = lookup(each.value.actions, "browser_check", null)
  }
}

# Firewall rules for advanced security (free on all plans)
resource "cloudflare_ruleset" "firewall_rules" {
  for_each = {
    for rule in local.firewall_rules : rule.key => rule
  }

  zone_id     = cloudflare_zone.domains[each.value.domain].id
  name        = each.value.description
  description = each.value.description
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = each.value.action
    expression  = each.value.expression
    description = each.value.description
    enabled     = each.value.enabled

    # Add action parameters for different actions
    dynamic "action_parameters" {
      for_each = each.value.action == "block" ? [1] : []
      content {
        response {
          status_code  = 403
          content_type = "text/plain"
          content      = "Access denied - suspicious activity detected"
        }
      }
    }

    dynamic "action_parameters" {
      for_each = each.value.action == "challenge" ? [1] : []
      content {}
    }

    dynamic "action_parameters" {
      for_each = each.value.action == "js_challenge" ? [1] : []
      content {}
    }
  }
}

# Rate limiting rules (free with limitations)
resource "cloudflare_ruleset" "rate_limit_rules" {
  for_each = {
    for rule in local.rate_limit_rules : rule.key => rule
  }

  zone_id     = cloudflare_zone.domains[each.value.domain].id
  name        = each.value.description
  description = each.value.description
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    action      = each.value.action
    expression  = each.value.expression
    description = each.value.description
    enabled     = each.value.enabled

    action_parameters {
      response {
        status_code  = 429
        content_type = "text/plain"
        content      = "Rate limit exceeded - please try again later"
      }
    }

    ratelimit {
      characteristics     = each.value.characteristics
      period              = each.value.period
      requests_per_period = each.value.requests_per_period
      mitigation_timeout  = 60
    }
  }
}

# Zone settings with comprehensive security configuration
resource "cloudflare_zone_settings_override" "zone_settings" {
  for_each = local.domains
  zone_id  = cloudflare_zone.domains[each.key].id

  settings {
    # SSL/TLS Security
    ssl                      = lookup(lookup(each.value, "zone_settings", {}), "ssl", var.default_zone_settings.ssl)
    always_use_https         = lookup(lookup(each.value, "zone_settings", {}), "always_use_https", "on")
    automatic_https_rewrites = lookup(lookup(each.value, "zone_settings", {}), "automatic_https_rewrites", var.default_zone_settings.automatic_https_rewrites)
    min_tls_version          = lookup(lookup(each.value, "zone_settings", {}), "min_tls_version", var.default_zone_settings.min_tls_version)
    tls_1_3                  = lookup(lookup(each.value, "zone_settings", {}), "tls_1_3", "on")
    opportunistic_encryption = lookup(lookup(each.value, "zone_settings", {}), "opportunistic_encryption", var.default_zone_settings.opportunistic_encryption)

    # Security Settings
    security_level      = lookup(lookup(each.value, "zone_settings", {}), "security_level", var.default_zone_settings.security_level)
    challenge_ttl       = lookup(lookup(each.value, "zone_settings", {}), "challenge_ttl", var.default_zone_settings.challenge_ttl)
    browser_check       = lookup(lookup(each.value, "zone_settings", {}), "browser_check", "on")
    hotlink_protection  = lookup(lookup(each.value, "zone_settings", {}), "hotlink_protection", var.default_zone_settings.hotlink_protection)
    email_obfuscation   = lookup(lookup(each.value, "zone_settings", {}), "email_obfuscation", var.default_zone_settings.email_obfuscation)
    server_side_exclude = lookup(lookup(each.value, "zone_settings", {}), "server_side_exclude", var.default_zone_settings.server_side_exclude)

    # Privacy & Bot Protection
    privacy_pass = lookup(lookup(each.value, "zone_settings", {}), "privacy_pass", "on")
    security_header {
      enabled            = lookup(lookup(lookup(each.value, "zone_settings", {}), "security_header", {}), "enabled", true)
      max_age            = lookup(lookup(lookup(each.value, "zone_settings", {}), "security_header", {}), "max_age", 31536000)
      include_subdomains = lookup(lookup(lookup(each.value, "zone_settings", {}), "security_header", {}), "include_subdomains", true)
      nosniff            = lookup(lookup(lookup(each.value, "zone_settings", {}), "security_header", {}), "nosniff", true)
    }

    # Performance Settings
    browser_cache_ttl = lookup(lookup(each.value, "zone_settings", {}), "browser_cache_ttl", var.default_zone_settings.browser_cache_ttl)
    development_mode  = lookup(lookup(each.value, "zone_settings", {}), "development_mode", var.default_zone_settings.development_mode)
    ip_geolocation    = lookup(lookup(each.value, "zone_settings", {}), "ip_geolocation", var.default_zone_settings.ip_geolocation)
    ipv6              = lookup(lookup(each.value, "zone_settings", {}), "ipv6", var.default_zone_settings.ipv6)
    rocket_loader     = lookup(lookup(each.value, "zone_settings", {}), "rocket_loader", var.default_zone_settings.rocket_loader)
    brotli            = lookup(lookup(each.value, "zone_settings", {}), "brotli", var.default_zone_settings.brotli)
    early_hints       = lookup(lookup(each.value, "zone_settings", {}), "early_hints", "on")
  }
}

# Web Application Firewall (WAF) - Managed Rules (free)
resource "cloudflare_ruleset" "waf_managed_rules" {
  for_each    = local.domains
  zone_id     = cloudflare_zone.domains[each.key].id
  name        = "WAF Managed Rules for ${each.key}"
  description = "Cloudflare Managed Ruleset for ${each.key}"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  # Enable Cloudflare Managed Ruleset (free)
  rules {
    action = "execute"
    action_parameters {
      id = "efb7b8c949ac4650a09736fc376e9aee" # Cloudflare Managed Ruleset
    }
    expression  = "true"
    description = "Execute Cloudflare Managed Ruleset"
    enabled     = true
  }

  # Enable OWASP Core Ruleset (free)
  rules {
    action = "execute"
    action_parameters {
      id = "4814384a9e5d4991b9815dcfc25d2f1f" # OWASP Core Ruleset
    }
    expression  = "true"
    description = "Execute OWASP Core Ruleset"
    enabled     = true
  }
}
