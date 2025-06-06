# Cloudflare Security Features Guide

This document outlines all the security features implemented in this Terraform configuration using Cloudflare's **free plan**.

## 🛡️ Security Features Overview

All these features are available on Cloudflare's free plan and provide enterprise-grade security without cost.

### 🔐 SSL/TLS Security

| Feature | Status | Description |
|---------|--------|-------------|
| **SSL Mode** | `strict` | Requires valid SSL certificate on origin server |
| **Always Use HTTPS** | `enabled` | Automatically redirects HTTP to HTTPS |
| **Automatic HTTPS Rewrites** | `enabled` | Rewrites HTTP links to HTTPS in HTML |
| **Minimum TLS Version** | `1.2` | Blocks connections using older TLS versions |
| **TLS 1.3** | `enabled` | Uses the latest TLS protocol for better security |
| **Opportunistic Encryption** | `enabled` | Enables encryption when possible |

### 🔥 Web Application Firewall (WAF)

#### Managed Rulesets (Free)
- **Cloudflare Managed Ruleset**: Protection against OWASP Top 10 and common vulnerabilities
- **OWASP Core Ruleset**: Industry-standard web application security rules

#### Custom Firewall Rules
1. **Block Bad Bots**: Blocks malicious bots while allowing legitimate crawlers
2. **Block Suspicious User Agents**: Blocks common attack tools (sqlmap, nikto, nessus)
3. **SQL Injection Protection**: Blocks common SQL injection patterns
4. **Path Traversal Protection**: Blocks directory traversal and common attack paths
5. **Optional Geo-blocking**: Challenge/block traffic from high-risk countries (disabled by default)

### 🚦 Rate Limiting & DDoS Protection

#### Built-in DDoS Protection
- **Unmetered DDoS protection** against Layer 3, 4, and 7 attacks
- **Always-on protection** with no traffic limits

#### Custom Rate Limiting Rules
1. **General Rate Limiting**: 100 requests per minute per IP
2. **Admin Endpoint Protection**: 5 requests per 5 minutes for admin/login pages
3. **API Protection**: 30 requests per minute for API endpoints

### 🛡️ Additional Security Features

| Feature | Description | Benefits |
|---------|-------------|----------|
| **DNSSEC** | DNS Security Extensions | Prevents DNS spoofing and cache poisoning |
| **Browser Integrity Check** | Validates browser headers | Blocks many automated attacks |
| **Hotlink Protection** | Prevents direct linking to resources | Saves bandwidth and prevents abuse |
| **Email Obfuscation** | Hides email addresses from scrapers | Reduces spam |
| **Server-Side Excludes** | Removes sensitive content | Prevents information disclosure |
| **Privacy Pass** | Reduces CAPTCHA challenges | Better user experience while maintaining security |

### 🔒 Security Headers

The configuration automatically adds security headers:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
```

### 📊 Security Analytics & Monitoring

Free analytics and monitoring features:
- **Security Analytics**: View all HTTP traffic and security events
- **DNS Analytics**: Monitor DNS queries and patterns
- **Real-time threat intelligence** from Cloudflare's network
- **Bot detection and scoring**

## 🎯 Security Configuration Examples

### High-Security Website
```yaml
zone_settings:
  ssl: "strict"
  security_level: "high"
  always_use_https: "on"
  min_tls_version: "1.2"
  browser_check: "on"
  hotlink_protection: "on"
```

### API Protection
```yaml
firewall_rules:
  - description: "API Rate Limiting"
    expression: 'http.request.uri.path contains "/api/"'
    action: "block"
    characteristics: ["ip.src"]
    period: 60
    requests_per_period: 30

rate_limit_rules:
  - description: "Strict API Limits"
    expression: 'http.request.uri.path contains "/api/"'
    action: "block"
    period: 60
    requests_per_period: 30
```

### Admin Panel Protection
```yaml
page_rules:
  - target: "yourdomain.com/admin*"
    priority: 1
    actions:
      security_level: "high"
      browser_check: "on"

firewall_rules:
  - description: "Admin Protection"
    expression: 'http.request.uri.path contains "/admin"'
    action: "challenge"
```

## 🔧 Security Best Practices

### 1. DNS Security
- **Enable DNSSEC**: Automatically enabled for all domains
- **Use CAA records**: Specify which Certificate Authorities can issue certificates
- **Implement SPF/DMARC**: Prevent email spoofing

### 2. SSL/TLS Configuration
- **Use "Strict" SSL mode**: Ensures end-to-end encryption
- **Enable TLS 1.3**: Better performance and security
- **Force HTTPS**: Redirect all HTTP traffic to HTTPS

### 3. Access Control
- **Implement rate limiting**: Prevent brute force attacks
- **Use geo-blocking carefully**: Consider legitimate users
- **Monitor security events**: Regular review of blocked requests

### 4. Content Security
- **Enable hotlink protection**: Prevent bandwidth theft
- **Use security headers**: Implement HSTS and content-type protection
- **Regular security audits**: Review firewall rules and settings

## 🚨 Threat Protection

### Protection Against:
- ✅ **DDoS attacks** (Layer 3, 4, 7)
- ✅ **SQL injection**
- ✅ **Cross-site scripting (XSS)**
- ✅ **Path traversal attacks**
- ✅ **Brute force attacks**
- ✅ **Bot attacks**
- ✅ **Scrapers and content theft**
- ✅ **Email spoofing** (with SPF/DMARC)
- ✅ **DNS attacks** (with DNSSEC)
- ✅ **SSL/TLS downgrade attacks**

### Advanced Threat Intelligence
- **Real-time threat feeds** from Cloudflare's global network
- **Automatic rule updates** for new threats
- **Machine learning-based bot detection**
- **15+ billion password database** for credential checking

## 📈 Monitoring & Alerting

### Available Metrics (Free)
- HTTP request volume and patterns
- Security event logs
- Bot score distributions
- DNS query analytics
- SSL/TLS certificate status

### Security Dashboard
Access your security metrics at:
- Cloudflare Dashboard → Security → Overview
- Analytics → Security for detailed breakdowns
- DNS Analytics for DNS-specific metrics

## 🔄 Maintenance & Updates

### Regular Tasks
1. **Review firewall logs**: Weekly review of blocked requests
2. **Update rate limits**: Adjust based on traffic patterns
3. **Monitor false positives**: Ensure legitimate traffic isn't blocked
4. **Security rule updates**: Cloudflare automatically updates managed rules

### Emergency Response
1. **Under Attack Mode**: Enable in dashboard for emergency DDoS protection
2. **Temporary IP blocks**: Add specific IPs to firewall rules
3. **Rate limit adjustments**: Increase strictness during attacks

## 🆓 Free vs Paid Features

### What's Free:
- ✅ Unmetered DDoS protection
- ✅ Web Application Firewall (WAF)
- ✅ SSL certificates
- ✅ Basic rate limiting
- ✅ Page rules (3 rules)
- ✅ DNSSEC
- ✅ Security analytics
- ✅ Bot protection

### Paid Upgrades Available:
- 🔄 **Advanced Rate Limiting**: More granular control ($5/month)
- 🔄 **Additional Page Rules**: More than 3 rules
- 🔄 **Advanced Bot Protection**: ML-based bot scoring
- 🔄 **Custom SSL certificates**: Bring your own certificates
- 🔄 **Load Balancing**: Geographic distribution ($5/month)

## 🛠️ Implementation Commands

```bash
# Apply security configuration
make apply

# Monitor security events
make output

# Check zone health
terraform output zone_ids

# Review DNS settings
make nameservers
```

## 📞 Security Support

### Resources:
- [Cloudflare Security Center](https://www.cloudflare.com/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Cloudflare Learning Center](https://www.cloudflare.com/learning/)

### Emergency:
- Enable "Under Attack Mode" in Cloudflare Dashboard
- Contact Cloudflare Support (paid plans)
- Review and adjust firewall rules immediately

---

**Note**: This configuration provides enterprise-grade security using only Cloudflare's free features. Regular monitoring and maintenance ensure optimal protection. 