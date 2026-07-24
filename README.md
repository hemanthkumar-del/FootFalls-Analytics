# FootFalls Analytics

An AI-powered retail footfall analytics system built with Flutter, FastAPI, Firebase Authentication, Firestore, MongoDB, and YOLOv8. It provides Google Sign-In, live occupancy tracking, entry/exit counting, an analytics dashboard, and real-time backend integration.

## Features
- **AI-Powered CCTV Analytics**: Real-time person detection and entry/exit counting using Ultralytics YOLO and native ByteTrack.
- **Cross-Platform Dashboard**: A dynamic, Riverpod-managed Flutter dashboard displaying live metrics over WebSockets.
- **Google Sign-In & Auth**: Secure onboarding via Firebase Authentication.
- **MongoDB Data Lake**: Highly scalable and index-optimized persistence for visitor logs.

## Tech Stack
- **Frontend**: Flutter, Riverpod, Dio, WebSockets, Material 3
- **Backend**: Python 3.12+, FastAPI, OpenCV, Ultralytics YOLO, MongoDB (Motor Async)
- **Infrastructure**: Firebase (Auth, Firestore)

## Project Structure
```text
FootFalls/
├── mobile-app/     # Flutter application
│   ├── lib/        # Dart source code (UI, Providers, Repositories, Models)
│   └── android/    # Android native configuration
└── backend/        # Python FastAPI application
    ├── app/        # API Routes, Services, WebSockets, MongoDB Repositories
    └── main.py     # Uvicorn entry point
```

## Installation & Setup

### 1. Flutter Setup
```bash
cd mobile-app
flutter pub get
flutter run
```

### 2. FastAPI Backend Setup
```bash
cd backend
python -m venv venv
# Activate venv
pip install -r requirements.txt
python main.py
```
*(Backend runs on `0.0.0.0:8000` by default)*

### 3. Firebase Configuration
To link your own Firebase project (Spark Plan compatible):
```bash
cd mobile-app
flutterfire configure
```
*(Ensure Google Sign-In is enabled in your Firebase Console and SHA keys are registered).*

## License
MIT License.
