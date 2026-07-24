# Release Notes - v1.0.0 (Production Release)

**Date**: July 24, 2026

We are incredibly excited to announce the production release of **FootFalls Analytics v1.0.0**. This release marks the culmination of an intensive four-phase development lifecycle aimed at bringing enterprise-grade computer vision directly into the hands of single-store retail owners.

## What's New?

### 🧠 Edge-Optimized AI Engine
Powered by YOLOv8 and ByteTrack, the local backend accurately tracks directional ingress and egress in real-time. Wait less, know more.

### 📊 Deterministic Business Intelligence
Say goodbye to complex spreadsheets. The new AI Insights Engine automatically cross-references your peak hours and historical traffic to offer plain-English staffing and layout recommendations.

### ⚙️ Hot-Reload Architecture
Add, edit, or remove cameras directly from the Flutter application. The python backend utilizes a custom `CameraWorkerRegistry` to instantly bind to the RTSP streams without dropping a single frame on other active feeds.

### 📱 Beautiful Cross-Platform Flutter Interface
Engineered heavily atop Material 3 and Riverpod 2.0, the native dashboard gives you sweeping operational control. Generate and export PDF reports directly to your local file system, configure store profiles, and visualize traffic through rich `fl_chart` graphing libraries.

## Security & Deployment Updates
- **Environment First**: All hardcoded parameters have been stripped in favor of `python-dotenv`.
- **CORS Enabled**: The backend natively accepts configurable Origins arrays.
- **Android Ready**: Production Gradle configuration templates have been applied. Follow the new Deployment Guide to build your AAB.

## Known Limitations
- Heatmap visuals are currently wire-framed in the API backend but require further tracking coordinate collection over time before rendering meaningful color gradients. 
- Maximum concurrent camera streaming is bottlenecked by the host machine's hardware acceleration capabilities (CUDA/TensorRT strongly recommended for 4+ cameras).
