# Changelog

All notable changes to the FootFalls Analytics project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-24

### Added - Phase 4 (Production Readiness)
- Fully dynamic `CameraWorkerRegistry` for hot-reloading capture threads without restarting the backend.
- Administrative CRUD operations for Camera Management via UI.
- Application `Settings` and `About` screens.
- Notifications Engine exposing system anomalies, occupancy warnings, and camera disconnections.
- Store Profile customization module dynamically backed by MongoDB.
- Backend `/health` endpoint using `psutil` for granular hardware metrics.

### Added - Phase 3 (Business Intelligence)
- Advanced deterministic Business Intelligence Rule Engine for localized recommendations.
- PDF and CSV reporting modules integrating `ReportLab`.
- `fl_chart` based Flutter interactive dashboard plotting hourly, daily, and weekly ingress vs egress metrics.
- Cartesian backend API hooks for eventual heatmap overlays.
- MongoDB Aggregation pipelines for sub-second dwell time calculations.

### Added - Phase 2 (Real-Time Camera Integration)
- Backend RTSP integration with Ultralytics YOLOv8.
- Custom WebSocket Binary streaming protocol (JSON metadata + JPEG bytes).
- Flutter `CustomPainter` overlay drawing synchronized bounding boxes and tracking IDs.
- ByteTrack integration for absolute bidirectional line counting accuracy.

### Added - Phase 1 (Authentication & Architecture)
- Repository setup for FastAPI and Flutter.
- Firebase integration (Google Sign-In).
- Initial project routing and scaffold navigation via `go_router`.
- MongoDB baseline connector.
