#!/bin/bash
# Script to get SHA-1 fingerprint from debug keystore
# This is needed for Google Sign-In configuration

echo "Getting SHA-1 fingerprint from debug keystore..."
echo ""

keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -E "(SHA1|SHA-1)" | head -1

echo ""
echo "=========================================="
echo "SHA-1 Fingerprint (copy this):"
echo "13:6A:D6:9D:8D:62:98:5F:D8:C2:95:EE:51:62:3D:23:F6:A5:27:BD"
echo "=========================================="
echo ""
echo "Add this SHA-1 to your Google Console:"
echo "1. Go to Google Cloud Console"
echo "2. Select your project"
echo "3. Go to APIs & Services > Credentials"
echo "4. Edit your OAuth 2.0 Client ID (Android)"
echo "5. Add this SHA-1 fingerprint"
echo "6. Package name: com.example.talktojesus"

