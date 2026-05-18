#!/bin/bash
set -e

# Update system packages
apt-get update
apt-get upgrade -y

# Install Node.js and npm
apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# Verify installation
node -v
npm -v

echo "User data script completed successfully"
