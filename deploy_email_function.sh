#!/bin/bash

# Spys E-pos Function Deployment Script
# Hierdie script sal die email function deploy en die API key opstel

set -e  # Stop on any error

echo "🚀 Deploying Spys Email Function..."
echo ""

# Navigate to project root
cd /Users/michaeldebeer/Projects/capstone

# Step 1: Set the Resend API Key
echo "📧 Setting up Resend API Key..."
supabase secrets set RESEND_API_KEY=re_GWHNJrrt_3NCit7tJG8AghmihiWEQiGzV --project-ref fdtjqpkrgstoobgkmvva

if [ $? -eq 0 ]; then
    echo "✅ API Key set successfully"
else
    echo "❌ Failed to set API key"
    echo "You may need to login first: supabase login"
    exit 1
fi

echo ""

# Step 2: Deploy the function
echo "🚀 Deploying send-email function..."
supabase functions deploy send-email --project-ref fdtjqpkrgstoobgkmvva

if [ $? -eq 0 ]; then
    echo "✅ Function deployed successfully"
else
    echo "❌ Failed to deploy function"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Run: flutter clean"
echo "2. Restart the admin app: cd apps/admin_web && flutter run -d chrome"
echo ""
echo "Then emails will work! 📧✨"
echo ""

