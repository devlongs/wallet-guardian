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

validate_address() {
    local addr=$1
    if [[ ! $addr =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo "Invalid address format: $addr"
        return 1
    fi
    return 0
}

# Monitoring parameters
ALERT_THRESHOLD_ETH=0.1           
CHECK_INTERVAL=60

monitor_address() {
    local address=$1
    local last_nonce=0
    
    while true; do
        local balance
        balance=$(cast balance "$address" || echo "error")
        
        if [ "$balance" != "error" ]; then
            # Check balance
            local balance_eth
            balance_eth=$(echo "scale=6; $balance / 1000000000000000000" | bc)
            
            echo "$(date): Checking $address (Balance: $balance_eth ETH)" | tee -a "$LOG_FILE"
            
            # Alert on low balance
            if (( $(echo "$balance_eth < $ALERT_THRESHOLD_ETH" | bc -l) )); then
                echo "⚠️ ALERT: Low balance detected for $address" | tee -a "$LOG_FILE"
                echo "Current balance: $balance_eth ETH" | tee -a "$LOG_FILE"
            fi
            
            # Check nonce for new transactions
            local current_nonce
            current_nonce=$(cast nonce "$address" || echo "error")
            
            if [ "$current_nonce" != "error" ] && [ "$current_nonce" -gt "$last_nonce" ]; then
                echo "🔔 Transaction detected for $address" | tee -a "$LOG_FILE"
                echo "Nonce increased from $last_nonce to $current_nonce" | tee -a "$LOG_FILE"
                last_nonce=$current_nonce
            fi
        else
            echo "Error fetching balance for $address" >> "$LOG_FILE"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

if [ -f "$ADDRESSES_FILE" ]; then
    while IFS= read -r address; do
        [[ -z "$address" || "$address" =~ ^# ]] && continue
        
        if validate_address "$address"; then
            monitor_address "$address" &
        fi
    done < "$ADDRESSES_FILE"
    
    wait
else
    echo "Error: $ADDRESSES_FILE not found"
    echo "Please create the file with one Ethereum address per line"
    exit 1
fi