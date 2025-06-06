#!/bin/bash

# Helper script to get zone information from Cloudflare
# Usage: ./get-zone-info.sh [domain_name]

set -e

# Check if domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain_name>"
    echo "Example: $0 iklobato.com"
    exit 1
fi

DOMAIN="$1"

# Check if API token is provided
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "Error: CLOUDFLARE_API_TOKEN environment variable is not set"
    echo ""
    echo "To get your API token:"
    echo "1. Go to https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Create a token with Zone:Read permissions"
    echo "3. Export it: export CLOUDFLARE_API_TOKEN='your_token_here'"
    exit 1
fi

echo "🔍 Looking up zone information for: $DOMAIN"
echo ""

# Get zone information
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json")

# Check if request was successful
SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" != "true" ]; then
    echo "❌ Error: Failed to get zone information"
    echo "Response: $RESPONSE"
    exit 1
fi

# Extract zone information
ZONE_ID=$(echo "$RESPONSE" | jq -r '.result[0].id // empty')
ZONE_NAME=$(echo "$RESPONSE" | jq -r '.result[0].name // empty')
ZONE_STATUS=$(echo "$RESPONSE" | jq -r '.result[0].status // empty')
PLAN_NAME=$(echo "$RESPONSE" | jq -r '.result[0].plan.name // empty')
NAME_SERVERS=$(echo "$RESPONSE" | jq -r '.result[0].name_servers[]? // empty' | tr '\n' ' ')

if [ -z "$ZONE_ID" ]; then
    echo "❌ Zone not found for domain: $DOMAIN"
    echo "Make sure the domain is added to your Cloudflare account."
    exit 1
fi

echo "✅ Zone found!"
echo ""
echo "📋 Zone Information:"
echo "   Domain:       $ZONE_NAME"
echo "   Zone ID:      $ZONE_ID"
echo "   Status:       $ZONE_STATUS"
echo "   Plan:         $PLAN_NAME"
echo "   Name Servers: $NAME_SERVERS"
echo ""
echo "🚀 To import this zone into Terraform, run:"
echo "   make import DOMAIN=$ZONE_NAME ZONE_ID=$ZONE_ID"
echo ""
echo "💡 Or manually:"
echo "   terraform import 'cloudflare_zone.domains[\"$ZONE_NAME\"]' $ZONE_ID" 