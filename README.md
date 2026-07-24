# FootFalls Analytics

![FootFalls Banner](https://via.placeholder.com/1200x400?text=FootFalls+Analytics)

**An AI-powered retail footfall analytics system.** Built with Flutter, FastAPI, Firebase Authentication, MongoDB, and YOLOv8. It provides Google Sign-In, live occupancy tracking, entry/exit counting, dynamic business intelligence dashboards, and a real-time binary websocket bridge.

---

## 🚀 Features

- **Real-Time Edge Processing**: Leverages YOLOv8 and ByteTrack to perform directional line-counting natively.
- **Ultra-Low Latency Streaming**: Custom WebSockets multiplex bounding-box metadata and JPEG frames.
- **Smart Store Management**: Configure multiple cameras, business hours, and profile settings on the fly.
- **AI Insights Engine**: Generates plain-text business recommendations dynamically based on historical MongoDB aggregations.
- **Comprehensive Reporting**: Export daily and weekly metrics to PDF and CSV formats.
- **Production Ready**: Fully dockerizable Python backend and highly scalable Riverpod architecture for Flutter.

---

## 🏗️ Architecture

```mermaid
graph TD;
    subgraph Frontend [Flutter Application]
        UI[Material 3 UI]
        State[Riverpod State]
        Auth[Firebase Auth SDK]
    end

    subgraph Backend [FastAPI Server]
        API[REST & WebSocket Routers]
        AuthGuard[JWT / Firebase Verification]
        WorkerRegistry[Camera Worker Registry]
        CVEngine[OpenCV + YOLOv8 + ByteTrack]
        BIEngine[AI Insights Engine]
    end

    subgraph Data [Persistence]
        Mongo[(MongoDB Atlas)]
        Firebase[(Firebase IAM)]
    end

    UI -->|State Updates| State
    State -->|HTTP Requests| API
    State -->|Binary Websocket| API
    Auth -->|Authenticate| Firebase
    Auth -->|Access Token| State

    API --> AuthGuard
    AuthGuard --> WorkerRegistry
    WorkerRegistry --> CVEngine
    CVEngine -->|Aggregation Pipelines| Mongo
    API --> BIEngine
    BIEngine -->|Metrics| Mongo
```

---

## 🛠️ Technology Stack

| Component | Technology |
| :--- | :--- |
| **Mobile App** | Flutter, Riverpod, Dio, fl_chart |
| **Backend API** | Python, FastAPI, Uvicorn, WebSockets |
| **Computer Vision** | OpenCV, Ultralytics YOLOv8, ByteTrack |
| **Database** | MongoDB (Motor Asyncio) |
| **Authentication** | Firebase Authentication (Google Sign-In) |

---

## 📂 Folder Structure

```text
FootFalls/
├── backend/                  # FastAPI Application
│   ├── app/
│   │   ├── api/              # REST Endpoints (cameras, health, store, analytics)
│   │   ├── core/             # Settings and Security
│   │   ├── repositories/     # MongoDB Abstraction Layer
│   │   ├── schemas/          # Pydantic Data Models
│   │   └── services/         # YOLO, Tracking, Workers, AI Insights
│   ├── main.py               # Application Entry Point
│   └── requirements.txt      # Python Dependencies
├── mobile-app/               # Flutter Application
│   ├── lib/
│   │   ├── core/             # Router, Config, Networking
│   │   ├── providers/        # Riverpod Controllers
│   │   └── screens/          # Material UI Views
│   ├── android/              # Native Android Build Configuration
│   └── pubspec.yaml          # Flutter Dependencies
├── CHANGELOG.md              # Version History
├── RELEASE_NOTES.md          # 1.0.0 Release Notes
└── DEPLOYMENT_GUIDE.md       # Production Deployment Manual
```

---

## ⚙️ Installation

### Backend Setup
1. Navigate to the backend directory: `cd backend`
2. Create a virtual environment: `python -m venv venv`
3. Activate it: `.\venv\Scripts\Activate` (Windows) or `source venv/bin/activate` (Mac/Linux)
4. Install dependencies: `pip install -r requirements.txt`
5. Copy environment template: `cp .env.example .env` and fill it out.
6. Run the server: `python main.py`

### Flutter Setup
1. Navigate to the frontend directory: `cd mobile-app`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

---

## 📚 API Documentation

### Cameras
- `GET /cameras/`: List all cameras.
- `POST /cameras/`: Register a new camera and trigger a capture thread.
- `PUT /cameras/{id}`: Modify a camera's URL or location.
- `DELETE /cameras/{id}`: Terminate thread and remove the camera.
- `GET /cameras/status`: Retrieve RAM footprint, uptime, and FPS metrics.

**Request Example (POST)**
```json
{
  "name": "Front Door",
  "url": "rtsp://admin:pass@192.168.1.100:554/stream1"
}
```

### Analytics & Reports
- `GET /analytics/advanced`: Fetches Dwell Time ranges and Peak Hours.
- `GET /analytics/export/pdf`: Streams a dynamically generated ReportLab PDF buffer.
- `GET /analytics/export/csv`: Streams a flat text comma-separated file.

### Management
- `GET /store/profile`: Fetch configuration details.
- `GET /notifications`: Retrieve warnings emitted by the AI Engine.
- `GET /health/`: Verify system resource utilization (CPU/Memory).

---

## 🔮 Future Scope
- **Multi-Store Management**: Expand RBAC models to support Franchise owners overseeing dozens of sub-stores.
- **Heatmap Generation**: Finalize the aggregation pipelines to dynamically paint floorplan traffic maps based on coordinate tracking history.
- **Hardware Acceleration**: Wrap the FastAPI container with DeepStream or TensorRT bindings to drastically lower the CPU footprint.

---

## 📄 License
This project is licensed under the MIT License.
