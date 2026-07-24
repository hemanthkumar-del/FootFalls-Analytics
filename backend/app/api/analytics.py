from fastapi import APIRouter, Depends
from datetime import datetime, timezone
from app.repositories.analytics_repository import AnalyticsRepository
from app.schemas.analytics import AnalyticsDashboardResponse, DailySummary

router = APIRouter()

def get_analytics_repo():
    return AnalyticsRepository()

@router.get("/dashboard", response_model=AnalyticsDashboardResponse)
async def get_dashboard(repo: AnalyticsRepository = Depends(get_analytics_repo)):
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    today_data = await repo.get_today_summary(today_str)
    
    return AnalyticsDashboardResponse(
        today_entries=today_data.get("total_entries", 0),
        today_exits=today_data.get("total_exits", 0),
        current_occupancy=today_data.get("peak_occupancy", 0), # Simplified for dashboard
        peak_hour=today_data.get("peak_hour", "N/A"),
        active_cameras=1 # Stubbed for now
    )

@router.get("/today", response_model=DailySummary)
async def get_today_analytics(repo: AnalyticsRepository = Depends(get_analytics_repo)):
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    return await repo.get_today_summary(today_str)

@router.get("/hourly")
async def get_hourly_analytics():
    return {"message": "Hourly analytics not implemented yet"}

@router.get("/weekly")
async def get_weekly_analytics():
    return {"message": "Weekly analytics not implemented yet"}

@router.get("/monthly")
async def get_monthly_analytics():
    return {"message": "Monthly analytics not implemented yet"}
