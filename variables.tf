variable "cloudflare_api_token" {
  description = "Cloudflare API token with appropriate permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_name" {
  description = "Cloudflare account name"
  type        = string
}

variable "domains_config_file" {
  description = "Path to the domains configuration file"
  type        = string
  default     = "domains.yaml"
}

variable "default_zone_settings" {
  description = "Default zone settings to apply to all domains"
  type = object({
    # SSL/TLS Security Settings
    ssl                      = optional(string, "strict")
    always_use_https         = optional(string, "on")
    automatic_https_rewrites = optional(string, "on")
    min_tls_version          = optional(string, "1.2")
    tls_1_3                  = optional(string, "on")
    opportunistic_encryption = optional(string, "on")

    # Security Settings
    security_level      = optional(string, "high")
    browser_cache_ttl   = optional(number, 14400)
    challenge_ttl       = optional(number, 1800)
    browser_check       = optional(string, "on")
    development_mode    = optional(string, "off")
    email_obfuscation   = optional(string, "on")
    hotlink_protection  = optional(string, "on")
    server_side_exclude = optional(string, "on")
    privacy_pass        = optional(string, "on")

    # Network & Performance
    ip_geolocation = optional(string, "on")
    ipv6           = optional(string, "on")
    rocket_loader  = optional(string, "off")
    brotli         = optional(string, "on")
    early_hints    = optional(string, "on")
  })
  default = {}
}
