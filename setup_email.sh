#!/bin/bash

echo "🚀 Spys E-pos Opstelling"
echo "========================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI nie geïnstalleer nie!"
    echo "Installeer dit met: brew install supabase/tap/supabase"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI gevind${NC}"
echo ""

# Step 1: Login
echo -e "${BLUE}Stap 1: Login by Supabase${NC}"
echo "Dit sal 'n browser oop maak - login met jou Supabase account"
echo ""
supabase login

if [ $? -ne 0 ]; then
    echo "❌ Login het misluk. Probeer weer."
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Suksesvol ingeteken${NC}"
echo ""

# Step 2: Link project
echo -e "${BLUE}Stap 2: Link jou Supabase project${NC}"
supabase link --project-ref fdtjqpkrgstoobgkmvva

if [ $? -ne 0 ]; then
    echo "❌ Project linking het misluk."
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Project gelink${NC}"
echo ""

# Step 3: Get API Key
echo -e "${YELLOW}Stap 3: Resend API Key${NC}"
echo ""
echo "Gaan na: https://resend.com/api-keys"
echo "1. Registreer / Login"
echo "2. Create API Key"
echo "3. Kopieer die key (begin met 're_')"
echo ""
read -p "Plak jou Resend API Key hier: " RESEND_KEY

if [ -z "$RESEND_KEY" ]; then
    echo "❌ Geen API key verskaf nie"
    exit 1
fi

# Step 4: Set secret
echo ""
echo -e "${BLUE}Stap 4: Stel API key op${NC}"
supabase secrets set RESEND_API_KEY="$RESEND_KEY"

if [ $? -ne 0 ]; then
    echo "❌ Kon nie secret stel nie"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ API key gestel${NC}"
echo ""

# Step 5: Deploy function
echo -e "${BLUE}Stap 5: Deploy send-email Edge Function${NC}"
supabase functions deploy send-email

if [ $? -ne 0 ]; then
    echo "❌ Function deployment het misluk"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Edge Function deployed!${NC}"
echo ""

# Success message
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 E-pos Opstelling Voltooi!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Volgende stappe:"
echo "1. Verander stuurEmail: false na true in die kode"
echo "2. Hardloop: flutter clean"
echo "3. Restart die admin app"
echo ""
echo "Dan sal gebruikers e-pos ontvang wanneer bestellings opdateer! 📧"
echo ""

