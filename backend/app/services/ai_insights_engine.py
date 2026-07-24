class AIInsightsEngine:
    def __init__(self):
        pass

    def generate_insights(self, hourly_trends, daily_trends, dwell_stats, current_occupancy):
        insights = []

        # 1. Peak Hour Analysis
        if hourly_trends:
            peak_hour = max(hourly_trends, key=lambda x: x["entries"] + x["exits"])
            peak_traffic = peak_hour["entries"] + peak_hour["exits"]
            if peak_traffic > 50:
                insights.append(f"High traffic detected around {peak_hour['hour']} ({peak_traffic} movements). Consider deploying 2 additional staff members.")
            elif peak_traffic > 0:
                insights.append(f"Traffic peaked at {peak_hour['hour']} with {peak_traffic} movements. Staffing levels appear adequate.")
            else:
                insights.append("Store is currently experiencing very low traffic.")

        # 2. Dwell Time Analysis
        avg_dwell = dwell_stats.get("avg_minutes", 0)
        if avg_dwell > 45:
            insights.append(f"Visitors are spending an average of {avg_dwell} minutes. Excellent engagement. Promote upsell items at checkout.")
        elif avg_dwell > 15:
            insights.append(f"Average dwell time is {avg_dwell} minutes. Healthy browsing behavior.")
        elif avg_dwell > 0:
            insights.append(f"Visitors are leaving quickly (avg {avg_dwell} mins). Review store layout and immediate product visibility.")

        # 3. Growth Trends (Daily)
        if len(daily_trends) >= 2:
            today_total = daily_trends[-1]["entries"]
            yday_total = daily_trends[-2]["entries"]
            if yday_total > 0:
                growth = ((today_total - yday_total) / yday_total) * 100
                if growth > 15:
                    insights.append(f"Traffic has surged by {growth:.1f}% compared to yesterday! Monitor stock levels.")
                elif growth < -15:
                    insights.append(f"Traffic is down by {abs(growth):.1f}% compared to yesterday. Consider running a flash promotion.")
        
        # 4. Occupancy Alert
        if current_occupancy > 100:
            insights.append(f"CRITICAL: High occupancy ({current_occupancy}). Ensure safety protocols and checkout efficiency.")

        if not insights:
            insights.append("Gathering more data to generate insights...")

        return insights
