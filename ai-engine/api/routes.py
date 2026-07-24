import time
from fastapi import APIRouter, Depends, status
from typing import List

from api.schemas import (
    HealthResponse, StatusResponse, EventResponse, EventsListResponse,
    CameraInfoResponse, ConfigResponse, VersionResponse, MessageResponse
)
from api.dependencies import get_counter_engine, get_event_manager, get_camera, get_fps_counter, get_engine
from config.settings import settings

router = APIRouter()

@router.get("/health", response_model=HealthResponse)
def health_check(engine = Depends(get_engine)):
    return HealthResponse(
        status="healthy",
        ai_engine_status="running" if engine.is_running else "stopped",
        camera_status="connected" if engine.camera.cap and engine.camera.cap.isOpened() else "disconnected",
        yolo_model_status="loaded",
        tracker_status="initialized",
        timestamp=time.time()
    )

from database.services import db_service

@router.get("/status", response_model=StatusResponse)
def get_status(counter = Depends(get_counter_engine), fps_counter = Depends(get_fps_counter), camera = Depends(get_camera)):
    stats = db_service.get_statistics()
    return StatusResponse(
        total_entered=stats["total_entered"],
        total_exited=stats["total_exited"],
        current_occupancy=stats["current_occupancy"],
        fps=fps_counter.get_fps(),
        camera_connected=camera.cap.isOpened() if camera.cap else False
    )

@router.get("/statistics", response_model=StatusResponse)
def get_statistics(counter = Depends(get_counter_engine), fps_counter = Depends(get_fps_counter), camera = Depends(get_camera)):
    return get_status(counter, fps_counter, camera)

@router.get("/events", response_model=EventsListResponse)
def get_events():
    events = db_service.get_recent_events(limit=100)
    event_responses = []
    for e in events:
        event_responses.append(EventResponse(
            event_id=e.get("event_id", ""),
            track_id=e.get("track_id", 0),
            direction=e.get("direction", ""),
            timestamp=e.get("timestamp", 0.0)
        ))
    return EventsListResponse(events=event_responses)

@router.get("/camera", response_model=CameraInfoResponse)
def get_camera_info(camera = Depends(get_camera), fps_counter = Depends(get_fps_counter)):
    is_connected = camera.cap.isOpened() if camera.cap else False
    cam_info = db_service.get_camera_info(fps_counter.get_fps(), is_connected)
        
    return CameraInfoResponse(
        camera_source=cam_info["camera_source"],
        resolution=cam_info.get("resolution"),
        fps=cam_info["fps"],
        connection_state=cam_info["connection_state"]
    )

@router.get("/config", response_model=ConfigResponse)
def get_config():
    conf = db_service.get_config()
    return ConfigResponse(
        confidence_threshold=conf["confidence_threshold"],
        tracker_type=conf["tracker_type"],
        max_lost_frames=conf["max_lost_frames"],
        virtual_line_start=conf["virtual_line_start"],
        virtual_line_end=conf["virtual_line_end"]
    )

@router.get("/version", response_model=VersionResponse)
def get_version():
    return VersionResponse(
        project_name="FootFalls",
        version="1.0.0",
        build_date="2026-07-23",
        ai_model="YOLOv8n",
        tracker="ByteTrack"
    )

@router.post("/reset", response_model=MessageResponse)
def reset_counters(counter = Depends(get_counter_engine), event_manager = Depends(get_event_manager)):
    counter.reset()
    event_manager.clear_history()
    return MessageResponse(message="Counters and event history reset successfully")
