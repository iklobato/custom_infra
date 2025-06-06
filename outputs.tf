output "domain_zones" {
  description = "Information about the created Cloudflare zones"
  value = {
    for domain, zone in cloudflare_zone.domains : domain => {
      zone_id      = zone.id
      name_servers = zone.name_servers
      status       = zone.status
      plan         = zone.plan
    }
  }
}

output "dns_records_summary" {
  description = "Summary of DNS records created for each domain"
  value = {
    for domain in keys(local.domains) : domain => [
      for record_key, record in cloudflare_record.dns_records : {
        name    = record.name
        type    = record.type
        value   = record.value
        proxied = record.proxied
      } if startswith(record_key, domain)
    ]
  }
}

output "name_servers_by_domain" {
  description = "Name servers for each domain (use these at your domain registrar)"
  value = {
    for domain, zone in cloudflare_zone.domains : domain => zone.name_servers
  }
}

output "zone_ids" {
  description = "Zone IDs for each domain"
  value = {
    for domain, zone in cloudflare_zone.domains : domain => zone.id
  }
  sensitive = false
} 