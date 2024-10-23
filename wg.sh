#!/bin/bash

# Wallet_Guardian - Wallet Security Monitor
# Requirements: cast (from Foundry), standard Linux tools

# Configuration
ADDRESSES_FILE="watchlist.txt"    
LOG_FILE="security_monitor.log"

touch "$LOG_FILE"
echo "$(date): Security monitor started" >> "$LOG_FILE"

echo "Starting security monitor..."