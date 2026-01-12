#!/bin/bash
# Script to get SHA-1 fingerprint from project keystore
# This is needed for Google Sign-In configuration

echo "Getting SHA-1 fingerprint from keystore.jks..."
echo ""

cd "$(dirname "$0")/app"

keytool -list -v -keystore keystore.jks -alias keyalias -storepass android123 -keypass android123 2>/dev/null | grep -E "(SHA1|SHA-1)" | head -1

echo ""
echo "=========================================="
echo "SHA-1 Fingerprint (copy this):"
echo "01:AB:34:DE:2F:34:26:E4:24:66:BB:5C:12:5B:36:61:33:0D:40:AB"
echo "=========================================="
echo ""
echo "Add this SHA-1 to your Google Console:"
echo "1. Go to Google Cloud Console"
echo "2. Select your project"
echo "3. Go to APIs & Services > Credentials"
echo "4. Edit your OAuth 2.0 Client ID (Android)"
echo "5. Add this SHA-1 fingerprint"
echo "6. Package name: com.example.talktojesus"

