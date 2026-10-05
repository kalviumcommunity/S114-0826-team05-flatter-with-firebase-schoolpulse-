<# 
.SYNOPSIS
    Complete SchoolPulse Deployment Script
.DESCRIPTION
    Automates Firebase configuration, rules deployment, index deployment, and app build
.NOTES
    Run as Administrator in PowerShell from project root
#>

param(
    [string]$FirebaseProjectId = "",
    [string]$AdminEmail = "",
    [string]$AdminPassword = "",
    [switch]$SkipFirebaseConfig,
    [switch]$SkipRulesDeploy,
    [switch]$SkipIndexesDeploy,
    [switch]$SkipBuild
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SchoolPulse Complete Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    
    $errors = @()
    
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        $errors += "Flutter not found in PATH"
    }
    
    if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
        $errors += "Firebase CLI not found. Run: npm install -g firebase-tools"
    }
    
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
        $errors += "Dart not found in PATH"
    }
    
    # Check flutterfire via dart pub global
    if (-not (Get-Command "dart" -ErrorAction SilentlyContinue)) {
        $errors += "Dart not found (needed for flutterfire)"
    }
    
    if ($errors.Count -gt 0) {
        Write-Host "Missing prerequisites:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    
    Write-Host "All prerequisites found" -ForegroundColor Green
}

# Configure FlutterFire
function Configure-Firebase {
    if ($SkipFirebaseConfig) {
        Write-Host "Skipping Firebase config" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Configuring FlutterFire..." -ForegroundColor Yellow
    
    if (-not $FirebaseProjectId) {
        Write-Host "Available Firebase projects:" -ForegroundColor Cyan
        dart pub global run flutterfire_cli:flutterfire projects
        
        $FirebaseProjectId = Read-Host "Enter your Firebase Project ID"
    }
    
    if (-not $FirebaseProjectId) {
        Write-Host "Project ID required!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Configuring for project: $FirebaseProjectId" -ForegroundColor Cyan
    dart pub global run flutterfire_cli:flutterfire configure --project=$FirebaseProjectId --yes
    
    if (-not (Test-Path "lib/firebase_options.dart")) {
        Write-Host "Failed to generate firebase_options.dart" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Firebase configured" -ForegroundColor Green
}

# Deploy Firestore Rules
function Deploy-FirestoreRules {
    if ($SkipRulesDeploy) {
        Write-Host "Skipping rules deploy" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Deploying Firestore security rules..." -ForegroundColor Yellow
    
    if (-not (Test-Path "firestore.rules")) {
        Write-Host "firestore.rules not found!" -ForegroundColor Red
        exit 1
    }
    
    firebase deploy --only firestore:rules --project=$FirebaseProjectId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Rules deployment failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Security rules deployed" -ForegroundColor Green
}

# Deploy Firestore Indexes
function Deploy-FirestoreIndexes {
    if ($SkipIndexesDeploy) {
        Write-Host "Skipping indexes deploy" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Deploying Firestore indexes..." -ForegroundColor Yellow
    
    if (-not (Test-Path "firestore.indexes.json")) {
        Write-Host "firestore.indexes.json not found!" -ForegroundColor Red
        exit 1
    }
    
    firebase deploy --only firestore:indexes --project=$FirebaseProjectId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Indexes deployment failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Indexes deployed" -ForegroundColor Green
}

# Build and run
function Build-And-Run {
    if ($SkipBuild) {
        Write-Host "Skipping build" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    flutter pub get
    
    Write-Host "Generating code..." -ForegroundColor Yellow
    flutter pub run build_runner build --delete-conflicting-outputs
    
    Write-Host "Running app on Chrome..." -ForegroundColor Yellow
    flutter run -d chrome --web-port 3000
}

# Create Super Admin
function Create-SuperAdmin {
    Write-Host "" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Super Admin Setup" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $AdminEmail) {
        $AdminEmail = Read-Host "Enter admin email"
    }
    
    if (-not $AdminPassword) {
        $AdminPassword = Read-Host "Enter admin password" -AsSecureString
        $AdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
    }
    
    Write-Host "Creating super admin user..." -ForegroundColor Yellow
    
    # Create user via Firebase Auth REST API
    $apiKey = (Get-Content "lib/firebase_options.dart" -Raw) -match 'apiKey: "([^"]+)"' | Out-Null; $matches[1]
    $projectId = $FirebaseProjectId
    
    $body = @{
        email = $AdminEmail
        password = $AdminPassword
        returnSecureToken = $true
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey" -Method Post -Body $body -ContentType "application/json"
        $uid = $response.localId
        Write-Host "Created user with UID: $uid" -ForegroundColor Green
    } catch {
        Write-Host "User creation failed (may already exist): $_" -ForegroundColor Yellow
        # Try to get existing user
        $signInBody = @{
            email = $AdminEmail
            password = $AdminPassword
            returnSecureToken = $true
        } | ConvertTo-Json
        $signInResponse = Invoke-RestMethod -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey" -Method Post -Body $signInBody -ContentType "application/json"
        $uid = $signInResponse.localId
        Write-Host "Using existing user UID: $uid" -ForegroundColor Green
    }
    
    # Set custom claims via Firebase Admin SDK (requires Node.js)
    Write-Host ""
    Write-Host "Setting super admin claims..." -ForegroundColor Yellow
    Write-Host "Run this in Firebase Console > Cloud Shell or local Node.js:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  admin.auth().setCustomUserClaims('$uid', {" -ForegroundColor Cyan
    Write-Host "    role: 'superAdmin'," -ForegroundColor Cyan
    Write-Host "    admin: true," -ForegroundColor Cyan
    Write-Host "    districtAdmin: true," -ForegroundColor Cyan
    Write-Host "    schoolAdmin: true," -ForegroundColor Cyan
    Write-Host "    teacher: true," -ForegroundColor Cyan
    Write-Host "    viewer: true," -ForegroundColor Cyan
    Write-Host "    permissions: ['*']" -ForegroundColor Cyan
    Write-Host "  })" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then sign out and sign back in to refresh token." -ForegroundColor Yellow
}

# Main execution
Write-Host "Starting deployment..." -ForegroundColor Cyan
Write-Host ""

Check-Prerequisites

# Get project ID if not provided
if (-not $FirebaseProjectId) {
    Write-Host "Available Firebase projects:" -ForegroundColor Cyan
    firebase projects:list
    $FirebaseProjectId = Read-Host "Enter your Firebase Project ID"
}

if (-not $FirebaseProjectId) {
    Write-Host "Project ID is required!" -ForegroundColor Red
    exit 1
}

Write-Host "Using project: $FirebaseProjectId" -ForegroundColor Cyan
Write-Host ""

Configure-Firebase
Deploy-FirestoreRules
Deploy-FirestoreIndexes

# Set global for functions
$global:FirebaseProjectId = $FirebaseProjectId

Create-SuperAdmin

Build-And-Run

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green