# SchoolPulse One-Command Deployment

## 🚀 Quick Start (Windows PowerShell)

```powershell
# Run from project root
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\deploy.ps1
```

## 🚀 Quick Start (Linux/Mac/Git Bash)

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 📋 What the Script Does Automatically

| Step | Action |
|------|--------|
| 1 | Checks Flutter, Firebase CLI, Dart are installed |
| 2 | Lists your Firebase projects |
| 3 | **Configures FlutterFire** → generates `lib/firebase_options.dart` |
| 4 | **Deploys Firestore Security Rules** (allows district selection) |
| 5 | **Deploys Firestore Indexes** (enables all queries) |
| 6 | Installs dependencies (`flutter pub get`) |
| 7 | Generates code (`build_runner`) |
| 8 | Creates **Super Admin** user via Firebase Auth |
| 9 | Shows **Custom Claims** command for super admin |
| 10 | **Runs app on Chrome** |

---

## 🔑 Required Inputs During Run

The script will prompt for:

```
1. Firebase Project ID  (select from list or type)
2. Admin Email          (for super admin account)
3. Admin Password       (for super admin account)
```

---

## ⚙️ Advanced Options (PowerShell)

```powershell
# Skip Firebase config (if already done)
.\deploy.ps1 -SkipFirebaseConfig

# Skip rules deploy
.\deploy.ps1 -SkipRulesDeploy

# Skip indexes deploy
.\deploy.ps1 -SkipIndexesDeploy

# Skip build/run (just deploy rules/indexes)
.\deploy.ps1 -SkipBuild

# Provide project ID directly
.\deploy.ps1 -FirebaseProjectId "my-project-123"

# Provide admin credentials
.\deploy.ps1 -AdminEmail "admin@school.edu" -AdminPassword "secure123"
```

---

## ✅ Manual Steps After Script Completes

The script **cannot** automatically set custom claims (requires Firebase Admin SDK). After script finishes:

1. **Copy the UID** shown in terminal output
2. Open **Firebase Console → Cloud Shell** (terminal icon top-right)
3. Run this command:

```javascript
admin.auth().setCustomUserClaims('UID_FROM_OUTPUT', {
  role: 'superAdmin',
  admin: true,
  districtAdmin: true,
  schoolAdmin: true,
  teacher: true,
  viewer: true,
  permissions: ['*']
})
```

4. **Sign out and sign back in** in the app to refresh token

---

## 🏗️ First-Time App Setup

After deployment and super admin setup:

| Step | Action |
|------|--------|
| 1 | Open app → **Sign Up** |
| 2 | Select **Super Admin** role |
| 3 | **Districts dropdown now works!** |
| 4 | Fill form → **Create Account** |
| 5 | Login → **Schools** tab |
| 6 | **Create Districts** → **Create Schools** |
| 7 | Other users can now register & select districts |

---

## 🔧 Troubleshooting

| Error | Fix |
|-------|-----|
| `flutterfire configure` fails | Run `firebase login` first |
| `Permission denied` on rules | Run `firebase login` and re-run script |
| `Index not found` | Script deploys indexes automatically |
| `District dropdown empty` | Create districts first as Super Admin |
| `Build failed` | Run `flutter clean && flutter pub get` then re-run |

---

## 📁 Files Used by Deployment

| File | Purpose |
|------|---------|
| `deploy.ps1` | Windows PowerShell deployment script |
| `deploy.sh` | Linux/Mac/Git Bash deployment script |
| `firestore.rules` | Security rules (public district read) |
| `firestore.indexes.json` | Composite indexes for all queries |
| `FIREBASE_SETUP.md` | Detailed manual setup guide |
| `lib/firebase_options.dart` | **Generated** - DO NOT COMMIT |

---

## 🎯 One-Line Commands

### Windows (PowerShell)
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; .\deploy.ps1
```

### Linux/Mac
```bash
chmod +x deploy.sh && ./deploy.sh
```

### With Parameters
```powershell
.\deploy.ps1 -FirebaseProjectId "my-school-123" -AdminEmail "admin@school.edu" -AdminPassword "secure123"
```

---

## 📞 Support

If deployment fails:

1. Check `flutter doctor -v`
2. Verify `firebase login` works
3. Ensure project has **Firestore** and **Storage** enabled
4. Check `FIREBASE_SETUP.md` for detailed manual steps

The scripts handle 95% of deployment automatically. The only manual step is setting custom claims in Firebase Console (requires Admin SDK access).