import numpy as np

# REMOVED: from typing import tuple (Not needed in modern Python!)

def analyze_chronic_trends(metric_history: list[float], threshold_variance: float = 0.15) -> tuple[bool, str]:
    """
    Analyzes historical tracking numbers (e.g., blood sugar array) using a rolling trend delta.
    Returns (is_adverse_trend, recommended_nudge_text).
    """
    if len(metric_history) < 4:
        return False, "Data baseline accumulating. Continue logging metrics daily."

    # Convert incoming array to a NumPy structure for fast processing
    data = np.array(metric_history)
    
    # Calculate the day-over-day changes
    deltas = np.diff(data)
    
    # Check for a sustained upward trajectory (e.g., blood sugar climbing for 3 consecutive points)
    consecutive_increases = 0
    for delta in reversed(deltas):
        if delta > 0:
            consecutive_increases += 1
        else:
            break

    # Scenario A: Consecutive escalating streak
    if consecutive_increases >= 3:
        return True, "Alert: Your metric logs show a steady upward trend over the last few days. Consider reviewing your diet or consulting your clinical care provider."

    # Scenario B: Significant variance check against the baseline average
    baseline_avg = np.mean(data[:-1])
    latest_reading = data[-1]
    
    percentage_deviation = (latest_reading - baseline_avg) / baseline_avg

    if percentage_deviation >= threshold_variance:
        return True, f"Alert: Your latest metric log is {percentage_deviation*100:.1f}% higher than your weekly average baseline parameters. Monitor closely."

    return False, "Your chronic condition tracking metrics remain stable within normal baseline parameters."