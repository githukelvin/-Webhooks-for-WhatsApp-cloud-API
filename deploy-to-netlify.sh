#!/bin/bash

echo "🚀 Deploying to Netlify..."

# Check if Netlify CLI is installed
if ! command -v netlify &> /dev/null; then
    echo "❌ Netlify CLI not found. Installing..."
    npm install -g netlify-cli
fi

# Login to Netlify (if not already logged in)
netlify status || netlify login

# Initialize site (if not already initialized)
if [ ! -f ".netlify/state.json" ]; then
    echo "🔧 Initializing new Netlify site..."
    netlify init
fi

# Deploy
echo "📦 Deploying..."
netlify deploy --prod

echo "✅ Deployment complete!"
echo "🔗 Your webhook URL: $(netlify status --json | jq -r '.site_url')/webhook"
