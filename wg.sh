#!/bin/bash

# Wallet_Guardian - Wallet Security Monitor
# Requirements: cast (from Foundry), standard Linux tools

# Configuration
ADDRESSES_FILE="watchlist.txt"    
LOG_FILE="security_monitor.log"

touch "$LOG_FILE"
echo "$(date): Security monitor started" >> "$LOG_FILE"

echo "Starting security monitor..."

# Add RPC configuration
RPC_URL="${INFURA_RPC_URL}"    
export ETH_RPC_URL="$RPC_URL"

if ! command -v cast &> /dev/null; then
    echo "Error: 'cast' is required. Please install Foundry."
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo "Error: INFURA_RPC_URL is not set"
    echo "Please export INFURA_RPC_URL='your-rpc-url'"
    exit 1
fi

if ! cast block-number &> /dev/null; then
    echo "Error: Cannot connect to network"
    echo "Please check your RPC connection: $RPC_URL"
    exit 1
fi

echo "$(date): Connected to network via $RPC_URL" >> "$LOG_FILE"