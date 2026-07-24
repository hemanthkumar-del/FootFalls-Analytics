from fastapi import Depends
from api.services import engine_service
from core.pipeline import FootFallsPipeline
from counting.counter import CounterEngine
from events.event_manager import EventManager
from utils.camera import Camera
from api.exceptions import AIEngineNotInitializedException

def get_engine() -> FootFallsPipeline:
    pipeline = engine_service.get_pipeline()
    if not pipeline:
        raise AIEngineNotInitializedException()
    return pipeline

def get_counter_engine(engine: FootFallsPipeline = Depends(get_engine)) -> CounterEngine:
    return engine.counter_engine

def get_event_manager(engine: FootFallsPipeline = Depends(get_engine)) -> EventManager:
    return engine.event_manager

def get_camera(engine: FootFallsPipeline = Depends(get_engine)) -> Camera:
    return engine.camera

def get_fps_counter(engine: FootFallsPipeline = Depends(get_engine)):
    return engine.fps_counter
