#!/bin/bash

# Configuration
ADDRESSES_FILE="watchlist.txt"  
LOG_FILE="security_monitor.log"
ALERT_THRESHOLD_ETH=0.1        
CHECK_INTERVAL=60              


RPC_URL="https://sepolia.infura.io/v3/"
export ETH_RPC_URL="$RPC_URL"

if ! command -v cast &> /dev/null; then
    echo "Error: 'cast' is required. Please install Foundry."
    exit 1
fi

if ! cast block-number &> /dev/null; then
    echo "Error: Cannot connect to Ethereum network"
    echo "Please check your RPC connection: $RPC_URL"
    exit 1
fi

# Initialize log file
touch "$LOG_FILE"
echo "$(date): Security monitor started" >> "$LOG_FILE"
echo "$(date): Connected to ETH network via $RPC_URL" >> "$LOG_FILE"

validate_address() {
    local addr=$1
    if [[ ! $addr =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo "Invalid address format: $addr"
        return 1
    fi
    return 0
}

check_address() {
    local address=$1
    
    local balance
    balance=$(cast balance "$address" || echo "error")
    
    if [ "$balance" != "error" ]; then
        local balance_eth
        balance_eth=$(echo "scale=6; $balance / 1000000000000000000" | bc)
        
        echo "$(date): Checking $address (Balance: $balance_eth ETH)" >> "$LOG_FILE"
        echo "Current balance for $address: $balance_eth ETH"  
        
        local txs
        txs=$(cast tx --from "$address" --json 2>/dev/null || echo "error")
        
        if [ "$txs" != "error" ]; then
            if (( $(echo "$balance_eth < $ALERT_THRESHOLD_ETH" | bc -l) )); then
                echo "⚠️ ALERT: Low balance detected for $address" | tee -a "$LOG_FILE"
                echo "Current balance: $balance_eth ETH" | tee -a "$LOG_FILE"
            fi
        else
            echo "Error fetching transactions for $address" >> "$LOG_FILE"
        fi
    else
        echo "Error fetching balance for $address" >> "$LOG_FILE"
    fi
}

# Main monitoring loop
echo "Starting security monitor..."
echo "Connected to ETH network via $RPC_URL"

while true; do
    if [ -f "$ADDRESSES_FILE" ]; then
        while IFS= read -r address; do
            [[ -z "$address" || "$address" =~ ^# ]] && continue
            
            if validate_address "$address"; then
                check_address "$address"
            fi
        done < "$ADDRESSES_FILE"
    else
        echo "Error: $ADDRESSES_FILE not found"
        echo "Please create the file with one Ethereum address per line"
        exit 1
    fi
    
    sleep "$CHECK_INTERVAL"
done