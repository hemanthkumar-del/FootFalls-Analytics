# Grafana Dashboard Guide

Once Prometheus is actively scraping the FootFalls backend, you can visualize the traffic in Grafana.

## Dashboard Setup
1. Open Grafana and add your Prometheus instance as a Data Source.
2. Create a new Dashboard.
3. Import the standard **FastAPI Dashboard (ID: 13610)** from Grafana Labs for out-of-the-box HTTP latency metrics.

## Custom AI Metrics
In the future, the backend can be expanded to push Custom Gauges (e.g., `footfalls_active_cameras`, `footfalls_current_occupancy`) directly into the Prometheus registry, which can then be visualized in a bespoke Grafana panel.
