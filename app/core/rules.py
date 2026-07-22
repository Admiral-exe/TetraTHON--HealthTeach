from app.models.schemas import TriageRequest

def evaluate_critical_vitals(request: TriageRequest) -> tuple[bool, list[str]]:
    """
    Checks numeric vitals against standard medical warning limits.
    Returns a tuple of (is_emergency, list_of_breached_red_flags).
    """
    is_emergency = False
    red_flags = []

    # 1. Hypoxia Check
    if request.spo2 is not None and request.spo2 < 90.0:
        is_emergency = True
        red_flags.append("Critical Oxygen Saturation Level (SpO2 below 90%)")

    # 2. Hypertensive Crisis Check
    if request.blood_pressure_sys is not None and request.blood_pressure_sys >= 180.0:
        is_emergency = True
        red_flags.append("Hypertensive Crisis Level (Systolic Blood Pressure >= 180 mmHg)")
        
    if request.blood_pressure_dia is not None and request.blood_pressure_dia >= 120.0:
        is_emergency = True
        red_flags.append("Hypertensive Crisis Level (Diastolic Blood Pressure >= 120 mmHg)")

    # 3. Severe Tachycardia / Bradycardia Checks
    if request.heart_rate is not None:
        if request.heart_rate > 130.0:
            is_emergency = True
            red_flags.append("Severe Tachycardia (Heart Rate > 130 BPM)")
        elif request.heart_rate < 45.0:
            is_emergency = True
            red_flags.append("Severe Bradycardia (Heart Rate < 45 BPM)")

    return is_emergency, red_flags