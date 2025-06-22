#!/bin/bash

echo "🔧 Setting up environment variables for Netlify..."

read -p "Enter your WhatsApp API TOKEN: " TOKEN
read -p "Enter your MYTOKEN (verification token): " MYTOKEN

if [ ! -z "$TOKEN" ] && [ ! -z "$MYTOKEN" ]; then
    netlify env:set TOKEN "$TOKEN"
    netlify env:set MYTOKEN "$MYTOKEN"
    echo "✅ Environment variables set successfully!"
else
    echo "❌ Please provide both TOKEN and MYTOKEN"
fi
