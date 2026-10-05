#!/bin/bash
# SchoolPulse Complete Deployment Script
# Run: chmod +x deploy.sh && ./deploy.sh

set -e  # Exit on error

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo -e "  SchoolPulse Complete Deployment"
echo -e "========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

command -v flutter >/dev/null 2>&1 || { echo -e "${RED}Flutter not found in PATH${NC}"; exit 1; }
command -v firebase >/dev/null 2>&1 || { echo -e "${RED}Firebase CLI not found. Run: npm install -g firebase-tools${NC}"; exit 1; }
command -v dart >/dev/null 2>&1 || { echo -e "${RED}Dart not found in PATH${NC}"; exit 1; }

echo -e "${GREEN}✓ All prerequisites found${NC}"

# Get project ID
if [ -z "$FIREBASE_PROJECT_ID" ]; then
    echo -e "${CYAN}Available Firebase projects:${NC}"
    flutterfire projects
    read -p "Enter your Firebase Project ID: " FIREBASE_PROJECT_ID
fi

if [ -z "$FIREBASE_PROJECT_ID" ]; then
    echo -e "${RED}Project ID is required!${NC}"
    exit 1
fi

echo -e "${CYAN}Using project: $FIREBASE_PROJECT_ID${NC}"
echo ""

# Configure FlutterFire
echo -e "${YELLOW}Configuring FlutterFire...${NC}"
flutterfire configure --project=$FIREBASE_PROJECT_ID --yes

if [ ! -f "lib/firebase_options.dart" ]; then
    echo -e "${RED}Failed to generate firebase_options.dart${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Firebase configured${NC}"

# Deploy Firestore Rules
echo -e "${YELLOW}Deploying Firestore security rules...${NC}"
firebase deploy --only firestore:rules --project=$FIREBASE_PROJECT_ID
echo -e "${GREEN}✓ Security rules deployed${NC}"

# Deploy Firestore Indexes
echo -e "${YELLOW}Deploying Firestore indexes...${NC}"
firebase deploy --only firestore:indexes --project=$FIREBASE_PROJECT_ID
echo -e "${GREEN}✓ Indexes deployed${NC}"

# Build
echo -e "${YELLOW}Installing dependencies...${NC}"
flutter pub get

echo -e "${YELLOW}Generating code...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs

echo -e "${GREEN}✓ Build complete${NC}"

# Super Admin Setup Instructions
echo ""
echo -e "${CYAN}========================================"
echo -e "  Super Admin Setup"
echo -e "========================================${NC}"
echo ""
read -p "Enter admin email: " ADMIN_EMAIL
read -s -p "Enter admin password: " ADMIN_PASSWORD
echo ""

# Create user via Firebase Auth REST API
API_KEY=$(grep -oP 'apiKey: "\K[^"]+' lib/firebase_options.dart | head -1)

BODY='{"email":"'"$ADMIN_EMAIL"'","password":"'"$ADMIN_PASSWORD"'","returnSecureToken":true}'

RESPONSE=$(curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY")

UID=$(echo $RESPONSE | grep -oP '"localId":"\K[^"]+')

if [ -z "$UID" ]; then
    # Try sign in if user exists
    RESPONSE=$(curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY" \
      -H "Content-Type: application/json" \
      -d "$BODY")
    UID=$(echo $RESPONSE | grep -oP '"localId":"\K[^"]+')
    echo -e "${YELLOW}Using existing user: $UID${NC}"
else
    echo -e "${GREEN}Created user: $UID${NC}"
fi

echo ""
echo -e "${CYAN}========================================"
echo -e "  Super Admin Claims Setup"
echo -e "========================================${NC}"
echo -e "${CYAN}Run this in Firebase Console > Cloud Shell:${NC}"
echo ""
echo -e "${CYAN}  admin.auth().setCustomUserClaims('$UID', {${NC}"
echo -e "${CYAN}    role: 'superAdmin',${NC}"
echo -e "${CYAN}    admin: true,${NC}"
echo -e "${CYAN}    districtAdmin: true,${NC}"
echo -e "${CYAN}    schoolAdmin: true,${NC}"
echo -e "${CYAN}    teacher: true,${NC}"
echo -e "${CYAN}    viewer: true,${NC}"
echo -e "${CYAN}    permissions: ['*']${NC}"
echo -e "${CYAN}  })${NC}"
echo ""
echo -e "${YELLOW}Then sign out and sign back in to refresh token.${NC}"
echo ""

# Run app
echo -e "${YELLOW}Starting app on Chrome...${NC}"
flutter run -d chrome --web-port 3000