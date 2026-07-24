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

@router.get("/advanced")
async def get_advanced_analytics(repo: AnalyticsRepository = Depends(get_analytics_repo)):
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    
    hourly = await repo.get_hourly_trends(today_str)
    daily = await repo.get_daily_trends(7)
    dwell = await repo.get_dwell_time_stats()
    
    # Calculate current occupancy from today's peak or current WS logic
    today_summary = await repo.get_today_summary(today_str)
    curr_occ = today_summary.get("peak_occupancy", 0) # approximation for insights

    # Generate Insights
    from app.services.ai_insights_engine import AIInsightsEngine
    engine = AIInsightsEngine()
    insights = engine.generate_insights(hourly, daily, dwell, curr_occ)

    return {
        "hourly": hourly,
        "daily": daily,
        "dwell": dwell,
        "insights": insights
    }

@router.get("/export/csv")
async def export_csv(repo: AnalyticsRepository = Depends(get_analytics_repo)):
    from fastapi.responses import PlainTextResponse
    from app.services.export_service import ExportService
    
    daily = await repo.get_daily_trends(30)
    csv_str = ExportService().generate_csv(daily, headers=["date", "entries", "exits"])
    
    return PlainTextResponse(
        content=csv_str,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=footfalls_report.csv"}
    )

@router.get("/export/pdf")
async def export_pdf(repo: AnalyticsRepository = Depends(get_analytics_repo)):
    from fastapi.responses import Response
    from app.services.export_service import ExportService
    from app.services.ai_insights_engine import AIInsightsEngine
    
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    hourly = await repo.get_hourly_trends(today_str)
    daily = await repo.get_daily_trends(7)
    dwell = await repo.get_dwell_time_stats()
    
    today_summary = await repo.get_today_summary(today_str)
    curr_occ = today_summary.get("peak_occupancy", 0)
    
    engine = AIInsightsEngine()
    insights = engine.generate_insights(hourly, daily, dwell, curr_occ)
    
    pdf_bytes = ExportService().generate_pdf("FootFalls Analytics Report", insights, daily)
    
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=footfalls_report.pdf"}
    )

@router.get("/heatmap")
async def get_heatmap():
    # Return mock zones and weights for the Flutter frontend
    return {
        "zones": [
            {"x": 0.2, "y": 0.3, "weight": 0.8},
            {"x": 0.5, "y": 0.5, "weight": 0.9},
            {"x": 0.8, "y": 0.2, "weight": 0.4},
            {"x": 0.5, "y": 0.8, "weight": 0.6},
            {"x": 0.1, "y": 0.9, "weight": 0.2},
        ]
    }
