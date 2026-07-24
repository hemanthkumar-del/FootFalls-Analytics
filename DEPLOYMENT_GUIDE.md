# Deployment Guide

This guide covers deploying the FootFalls Analytics backend to modern PaaS providers (Railway/Render) and building the production Flutter application.

## 1. Backend Deployment (Railway / Render)

### Prerequisites
- A MongoDB Atlas account and cluster.
- A Firebase Project (with Authentication enabled).
- A GitHub repository containing the FootFalls source code.

### Step 1: Database Setup
1. Log into MongoDB Atlas.
2. Under "Network Access", ensure `0.0.0.0/0` is permitted (or the specific static IP of your Railway/Render instance).
3. Retrieve your Connection String (URI). Replace `<password>` with your database user password.

### Step 2: PaaS Configuration
1. Connect your GitHub repository to your PaaS of choice.
2. Set the Root Directory to `backend/`.
3. Set the Start Command to: `uvicorn main:app --host 0.0.0.0 --port $PORT`
4. Inject the following Environment Variables in the provider's dashboard:

```env
ENVIRONMENT=production
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/?retryWrites=true&w=majority
DB_NAME=footfalls_db
JWT_SECRET=generate_a_strong_random_secret_here
FIREBASE_PROJECT_ID=your-project-id
CORS_ORIGINS=https://your-frontend-domain.com
```

### Step 3: Deployment
- Trigger the build. The provider will install `requirements.txt`.
- Once online, verify the deployment by visiting `https://<your-backend-url>/health/`.

---

## 2. Flutter Android Release Build

### Step 1: Generate the Production Keystore
Open a terminal and run:
```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Keep this file secure. Do not commit it to version control!*

### Step 2: Configure key.properties
1. Place the generated `release.jks` inside `mobile-app/android/app/`.
2. Duplicate `key.properties.example` and rename it to `key.properties`.
3. Fill in your passwords and alias:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=release.jks
```

### Step 3: Build the App Bundle
Navigate to the `mobile-app` directory and run:
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-backend-url>
```
The final App Bundle will be located at `build/app/outputs/bundle/release/app-release.aab`. You can upload this directly to the Google Play Console.
