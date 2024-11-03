#!/bin/bash

# DNS Benchmark CLI Application 2024
# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color
DIM='\033[2m'

# Function for centered text with padding
center_text() {
    local text="$1"
    local width="$2"
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
}

# ASCII Art Banner
print_banner() {
    echo -e "${CYAN}"
    echo '╔══════════════════════════════════════════════════════════════════════════════╗'
    echo '║                                                                              ║'
    echo '║   ██████╗ ███╗   ██╗███████╗    ████████╗███████╗███████╗████████╗         ║'
    echo '║   ██╔══██╗████╗  ██║██╔════╝    ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝         ║'
    echo '║   ██║  ██║██╔██╗ ██║███████╗       ██║   █████╗  ███████╗   ██║            ║'
    echo '║   ██║  ██║██║╚██╗██║╚════██║       ██║   ██╔══╝  ╚════██║   ██║            ║'
    echo '║   ██████╔╝██║ ╚████║███████║       ██║   ███████╗███████║   ██║            ║'
    echo '║   ╚═════╝ ╚═╝  ╚═══╝╚══════╝       ╚═╝   ╚══════╝╚══════╝   ╚═╝            ║'
    echo '║                                                                              ║'
    echo '╚══════════════════════════════════════════════════════════════════════════════╝'
    echo -e "${NC}"
    echo -e "${PURPLE}                        DNS Benchmark Tool v2.0 (2024)${NC}"
    echo -e "${DIM}                   Performance testing for DNS resolvers${NC}"
    echo
}

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Error handling
set -e
trap 'echo -e "${RED}❌ Error on line $LINENO. Exit code: $?${NC}"' ERR

# Function to check if a command exists
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Progress bar function
progress_bar() {
    local duration=$1
    local width=50
    local progress=0
    local fill
    local empty
    while [ $progress -le 100 ]; do
        let fill=($progress*$width/100)
        let empty=($width-$fill)
        printf "\r[${CYAN}"
        printf "%${fill}s" '' | tr ' ' '█'
        printf "${NC}"
        printf "%${empty}s" '' | tr ' ' '░'
        printf "] ${YELLOW}$progress%%${NC}"
        let progress=progress+2
        sleep "$duration"
    done
    echo
}

# Check prerequisites with nice formatting
echo -e "\n${BOLD}🔍 Checking Prerequisites...${NC}"
sleep 0.5

if ! check_command bc; then
    echo -e "${RED}❌ 'bc' calculator not found. Please install bc.${NC}"
    exit 1
else
    echo -e "${GREEN}✔ bc found${NC}"
fi

if ! check_command dig; then
    if check_command drill; then
        alias dig="drill"
        echo -e "${YELLOW}ℹ Using 'drill' instead of 'dig'${NC}"
    else
        echo -e "${RED}❌ Neither 'dig' nor 'drill' found. Please install dnsutils/bind-tools or ldns.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✔ dig found${NC}"
fi

# Print banner
print_banner

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

# Popular domains to test
DOMAINS2TEST="www.google.com amazon.com facebook.com netflix.com microsoft.com
apple.com twitter.com instagram.com linkedin.com zoom.us teams.microsoft.com
github.com youtube.com tiktok.com reddit.com"

# Function to perform DNS query and get response time
get_dns_response_time() {
    local dns_server=$1
    local domain=$2
    local timeout=2
    
    if command -v timeout >/dev/null 2>&1; then
        result=$(timeout $timeout dig @"$dns_server" "$domain" +tries=1 +time=2 +stats 2>/dev/null | grep "Query time:" | awk '{print $4}')
    else
        result=$(dig @"$dns_server" "$domain" +tries=1 +time=2 +stats 2>/dev/null | grep "Query time:" | awk '{print $4}')
    fi
    
    if [ -z "$result" ]; then
        echo "1000"
    else
        echo "$result"
    fi
}

# Print test information
echo -e "\n${BOLD}🎯 Test Configuration${NC}"
echo -e "${DIM}────────────────────────${NC}"
echo -e "${CYAN}➜ Total DNS Providers:${NC} $(echo "$PROVIDERS" | grep -c '^')"
echo -e "${CYAN}➜ Domains to Test:${NC} $(echo "$DOMAINS2TEST" | wc -w)"
echo -e "${CYAN}➜ Timeout:${NC} 2 seconds"
echo

# Preparing test environment
echo -e "${BOLD}⚡ Initializing Test Environment${NC}"
progress_bar 0.03
echo

# Print header with fancy formatting
printf "${BOLD}%-18s${NC}" "DNS Provider"
total_domains=0
for domain in $DOMAINS2TEST; do
    total_domains=$((total_domains + 1))
    printf "${CYAN}%-8s${NC}" "T$total_domains"
done
printf "${YELLOW}%-10s${NC}" "Average"
echo

# Print separator line
echo -e "${DIM}$(printf '%0.s─' {1..120})${NC}"

# Test each provider
for provider in $PROVIDERS; do
    dns_ip=$(echo "$provider" | cut -d'#' -f1)
    dns_name=$(echo "$provider" | cut -d'#' -f2)
    
    total_time=0
    printf "${BOLD}%-18s${NC}" "$dns_name"
    
    for domain in $DOMAINS2TEST; do
        response_time=$(get_dns_response_time "$dns_ip" "$domain")
        total_time=$((total_time + response_time))
        
        # Color code the response times
        if [ "$response_time" -lt 50 ]; then
            printf "${GREEN}%-8s${NC}" "${response_time}ms"
        elif [ "$response_time" -lt 100 ]; then
            printf "${YELLOW}%-8s${NC}" "${response_time}ms"
        else
            printf "${RED}%-8s${NC}" "${response_time}ms"
        fi
    done
    
    # Calculate and print average
    avg=$(echo "scale=2; $total_time/$total_domains" | bc)
    if (( $(echo "$avg < 50" | bc -l) )); then
        printf "${GREEN}%-10s${NC}" "$avg"
    elif (( $(echo "$avg < 100" | bc -l) )); then
        printf "${YELLOW}%-10s${NC}" "$avg"
    else
        printf "${RED}%-10s${NC}" "$avg"
    fi
    echo
done

# Print separator line
echo -e "${DIM}$(printf '%0.s─' {1..120})${NC}"

# Summary
echo -e "\n${BOLD}📊 Test Summary${NC}"
echo -e "${DIM}────────────────${NC}"
echo -e "${CYAN}➜ Test completed at:${NC} $(date)"
echo -e "${CYAN}➜ Total domains tested:${NC} $total_domains"
echo -e "${CYAN}➜ Total DNS providers tested:${NC} $(echo "$PROVIDERS" | grep -c '^')"

# Footer
echo -e "\n${DIM}Report generated by DNS Benchmark Tool v2.0${NC}"
echo -e "${DIM}Copyright © 2024 - All rights reserved${NC}"
echo

exit 0