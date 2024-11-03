#!/bin/bash

# DNS Benchmark Script 2024
# Tests DNS resolver performance across multiple providers
# Compatible with Linux and macOS

# Error handling
set -e
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

# Function to check if a command exists
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Check for required utilities
if ! check_command bc; then
    echo "Error: 'bc' calculator not found. Please install bc."
    exit 1
fi

# Check for DNS tools (dig or drill)
if ! check_command dig; then
    if check_command drill; then
        alias dig="drill"
        echo "Using 'drill' instead of 'dig'"
    else
        echo "Error: Neither 'dig' nor 'drill' found. Please install dnsutils/bind-tools or ldns."
        exit 1
    fi
fi

# Modern DNS Providers for 2024
PROVIDERS="
1.1.1.1#Cloudflare-1
1.0.0.1#Cloudflare-2
8.8.8.8#Google-1
8.8.4.4#Google-2
9.9.9.9#Quad9-1
149.112.112.112#Quad9-2
208.67.222.222#OpenDNS-1
208.67.220.220#OpenDNS-2
94.140.14.14#AdGuard-1
94.140.15.15#AdGuard-2
185.228.168.168#CleanBrowsing-1
185.228.169.168#CleanBrowsing-2
76.76.2.0#Control-D-1
76.76.10.0#Control-D-2
4.2.2.1#Level3-1
4.2.2.2#Level3-2"

# Popular domains to test (including modern services)
DOMAINS2TEST="www.google.com amazon.com facebook.com netflix.com microsoft.com
apple.com twitter.com instagram.com linkedin.com zoom.us teams.microsoft.com
github.com youtube.com tiktok.com reddit.com"

# Function to perform DNS query and get response time
get_dns_response_time() {
    local dns_server=$1
    local domain=$2
    local timeout=2  # 2 second timeout
    
    # Use timeout command if available
    if command -v timeout >/dev/null 2>&1; then
        result=$(timeout $timeout dig @"$dns_server" "$domain" +tries=1 +time=2 +stats 2>/dev/null | grep "Query time:" | awk '{print $4}')
    else
        result=$(dig @"$dns_server" "$domain" +tries=1 +time=2 +stats 2>/dev/null | grep "Query time:" | awk '{print $4}')
    fi
    
    # Check if we got a result
    if [ -z "$result" ]; then
        echo "1000"  # Timeout value in ms
    else
        echo "$result"
    fi
}

# Print header
printf "%-18s" "DNS Provider"
total_domains=0
for domain in $DOMAINS2TEST; do
    total_domains=$((total_domains + 1))
    printf "%-8s" "T$total_domains"
done
printf "%-10s" "Average"
echo ""

# Print separator line
printf "%0.s-" {1..120}
echo ""

# Test each provider
for provider in $PROVIDERS; do
    # Split provider info
    dns_ip=$(echo "$provider" | cut -d'#' -f1)
    dns_name=$(echo "$provider" | cut -d'#' -f2)
    
    # Initialize total time
    total_time=0
    
    # Print provider name
    printf "%-18s" "$dns_name"
    
    # Test each domain
    for domain in $DOMAINS2TEST; do
        response_time=$(get_dns_response_time "$dns_ip" "$domain")
        total_time=$((total_time + response_time))
        printf "%-8s" "${response_time}ms"
    done
    
    # Calculate and print average
    avg=$(echo "scale=2; $total_time/$total_domains" | bc)
    printf "%-10s" "$avg"
    echo ""
done

# Print separator line
printf "%0.s-" {1..120}
echo ""

echo -e "\nTest completed at $(date)"
echo "Total domains tested: $total_domains"
echo "Total DNS providers tested: $(echo "$PROVIDERS" | grep -c '^')"

exit 0
