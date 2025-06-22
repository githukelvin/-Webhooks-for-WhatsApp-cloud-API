#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f "index.js" ]; then
    print_error "This doesn't appear to be your Node.js project directory."
    print_error "Please run this script from the directory containing package.json and index.js"
    exit 1
fi

print_status "Starting Netlify Functions setup..."

# Create backup of original files
print_step "1. Creating backup of original files..."
mkdir -p backup
cp index.js backup/index.js.backup
cp package.json backup/package.json.backup
print_status "Backup created in ./backup/"

# Create Netlify Functions directory structure
print_step "2. Creating Netlify Functions directory structure..."
mkdir -p netlify/functions

# Create the webhook function
print_step "3. Creating webhook function..."
cat > netlify/functions/webhook.js << 'EOF'
const axios = require("axios");

const token = process.env.TOKEN;
const mytoken = process.env.MYTOKEN;

exports.handler = async (event, context) => {
    const { httpMethod, queryStringParameters, body } = event;

    // Handle GET request for webhook verification
    if (httpMethod === "GET") {
        const mode = queryStringParameters["hub.mode"];
        const challenge = queryStringParameters["hub.challenge"];
        const verify_token = queryStringParameters["hub.verify_token"];

        if (mode && verify_token) {
            if (mode === "subscribe" && verify_token === mytoken) {
                return {
                    statusCode: 200,
                    body: challenge
                };
            } else {
                return {
                    statusCode: 403,
                    body: "Forbidden"
                };
            }
        }
    }

    // Handle POST request for incoming messages
    if (httpMethod === "POST") {
        try {
            const body_param = JSON.parse(body);

            console.log(JSON.stringify(body_param, null, 2));

            if (body_param.object) {
                console.log("inside body param");

                if (body_param.entry &&
                    body_param.entry[0].changes &&
                    body_param.entry[0].changes[0].value.messages &&
                    body_param.entry[0].changes[0].value.messages[0]) {

                    const phon_no_id = body_param.entry[0].changes[0].value.metadata.phone_number_id;
                    const from = body_param.entry[0].changes[0].value.messages[0].from;
                    const msg_body = body_param.entry[0].changes[0].value.messages[0].text.body;

                    console.log("phone number " + phon_no_id);
                    console.log("from " + from);
                    console.log("body param " + msg_body);

                    await axios({
                        method: "POST",
                        url: `https://graph.facebook.com/v13.0/${phon_no_id}/messages?access_token=${token}`,
                        data: {
                            messaging_product: "whatsapp",
                            to: from,
                            text: {
                                body: `Hi.. I'm Prasath, your message is ${msg_body}`
                            }
                        },
                        headers: {
                            "Content-Type": "application/json"
                        }
                    });

                    return {
                        statusCode: 200,
                        body: "OK"
                    };
                } else {
                    return {
                        statusCode: 404,
                        body: "Not Found"
                    };
                }
            }
        } catch (error) {
            console.error("Error:", error);
            return {
                statusCode: 500,
                body: "Internal Server Error"
            };
        }
    }

    return {
        statusCode: 405,
        body: "Method Not Allowed"
    };
};
EOF

print_status "Webhook function created"

# Create package.json for functions
print_step "4. Creating package.json for functions..."
cat > netlify/functions/package.json << 'EOF'
{
  "name": "netlify-functions",
  "version": "1.0.0",
  "dependencies": {
    "axios": "^1.10.0"
  }
}
EOF

print_status "Functions package.json created"

# Create netlify.toml configuration
print_step "5. Creating Netlify configuration..."
cat > netlify.toml << 'EOF'
[build]
  functions = "netlify/functions"

[functions]
  node_bundler = "esbuild"

[[redirects]]
  from = "/webhook"
  to = "/.netlify/functions/webhook"
  status = 200

[[redirects]]
  from = "/"
  to = "/index.html"
  status = 200
EOF

print_status "netlify.toml created"

# Create index.html
print_step "6. Creating index.html..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WhatsApp Webhook</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        h1 {
            color: #25D366;
            margin-bottom: 20px;
        }
        .status {
            background: #e8f5e8;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border-left: 4px solid #25D366;
        }
        .webhook-url {
            background: #f0f0f0;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            word-break: break-all;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 WhatsApp Webhook Setup</h1>
        <div class="status">
            <strong>✅ Successfully deployed on Netlify!</strong>
        </div>
        <p>Your WhatsApp webhook is now running as a serverless function.</p>

        <h3>Webhook URL:</h3>
        <div class="webhook-url">
            https://your-site-name.netlify.app/webhook
        </div>

        <p><small>Replace "your-site-name" with your actual Netlify site name</small></p>

        <h3>📋 Next Steps:</h3>
        <ol style="text-align: left;">
            <li>Set environment variables (TOKEN and MYTOKEN) in Netlify dashboard</li>
            <li>Update your WhatsApp Business API webhook URL</li>
            <li>Test the webhook verification</li>
        </ol>
    </div>
</body>
</html>
EOF

print_status "index.html created"

# Create .gitignore if it doesn't exist
print_step "7. Creating/updating .gitignore..."
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
node_modules/
.env
.netlify/
dist/
backup/
*.log
EOF
else
    # Add Netlify-specific entries if they don't exist
    grep -qxF ".netlify/" .gitignore || echo ".netlify/" >> .gitignore
    grep -qxF "backup/" .gitignore || echo "backup/" >> .gitignore
fi

print_status ".gitignore updated"

# Create a simple deployment script
print_step "8. Creating deployment helper script..."
cat > deploy-to-netlify.sh << 'EOF'
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
EOF

chmod +x deploy-to-netlify.sh

print_status "Deployment script created (deploy-to-netlify.sh)"

# Create environment setup script
print_step "9. Creating environment setup helper..."
cat > setup-env-vars.sh << 'EOF'
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
EOF

chmod +x setup-env-vars.sh

print_status "Environment setup script created (setup-env-vars.sh)"

# Install dependencies if needed
print_step "10. Installing dependencies..."
if [ -d "netlify/functions" ]; then
    cd netlify/functions
    npm install
    cd ../..
fi

print_status "Dependencies installed"

# Final summary
print_step "✅ Setup Complete!"
echo ""
print_status "Your project has been converted for Netlify deployment!"
echo ""
echo -e "${BLUE}📁 Files created:${NC}"
echo "  ├── netlify/functions/webhook.js"
echo "  ├── netlify/functions/package.json"
echo "  ├── netlify.toml"
echo "  ├── index.html"
echo "  ├── deploy-to-netlify.sh"
echo "  ├── setup-env-vars.sh"
echo "  └── backup/ (your original files)"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "1. Install Netlify CLI: npm install -g netlify-cli"
echo "2. Run: ./deploy-to-netlify.sh"
echo "3. Run: ./setup-env-vars.sh (to set environment variables)"
echo "4. Your webhook URL will be: https://your-site-name.netlify.app/webhook"
echo ""
print_warning "Don't forget to update your WhatsApp webhook URL and set environment variables!"
