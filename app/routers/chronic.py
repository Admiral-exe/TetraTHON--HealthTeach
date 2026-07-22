from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from io import BytesIO
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

from app.models.schemas import MetricTrendRequest, MetricTrendResponse, ReportGenerationRequest
from app.core.statistics import analyze_chronic_trends

router = APIRouter(prefix="/chronic", tags=["Phase 2: Chronic Management"])

@router.post("/check-trends", response_model=MetricTrendResponse)
async def check_trends(payload: MetricTrendRequest):
    """Evaluates time-series health records for deviations and generates live contextual nudges."""
    is_adverse, nudge = analyze_chronic_trends(payload.metric_history)
    return MetricTrendResponse(is_adverse_trend=is_adverse, nudge_text=nudge)

@router.post("/generate-report")
async def generate_report(payload: ReportGenerationRequest):
    """Compiles local log telemetry arrays into a downloadable clinician summary PDF document."""
    try:
        # Create an in-memory buffer so we don't dump temporary files to the disk
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
        story = []
        
        styles = getSampleStyleSheet()
        
        # Define Custom Canvas Colors and Typography Layout styles
        title_style = ParagraphStyle(
            'ReportTitle',
            parent=styles['Heading1'],
            fontSize=22,
            textColor=colors.HexColor("#007A78"), # Clinical Teal
            spaceAfter=15
        )
        
        # Build Document Content
        story.append(Paragraph(f"Weekly Clinician Summary Report", title_style))
        story.append(Paragraph(f"<b>Condition:</b> {payload.condition_name}", styles['Normal']))
        story.append(Spacer(1, 15))
        
        # Render Metrics Grid Table
        table_data = [["Day / Log Index", "Recorded Value Mapping"]]
        for index, value in enumerate(payload.weekly_metrics):
            table_data.append([f"Log Point {index + 1}", f"{value}"])
            
        metrics_table = Table(table_data, colWidths=[200, 200])
        metrics_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (1,0), colors.HexColor("#007A78")),
            ('TEXTCOLOR', (0,0), (1,0), colors.whitesmoke),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('FONTNAME', (0,0), (1,0), 'Helvetica-Bold'),
            ('BOTTOMPADDING', (0,0), (-1,-1), 8),
            ('BACKGROUND', (0,1), (-1,-1), colors.HexColor("#F4F9F9")),
            ('GRID', (0,0), (-1,-1), 0.5, colors.lightgrey)
        ]))
        
        story.append(Paragraph("<b>Recent Telemetry Metric Array:</b>", styles['Heading3']))
        story.append(Spacer(1, 5))
        story.append(metrics_table)
        story.append(Spacer(1, 20))
        
        # Append Automated Summaries
        story.append(Paragraph("<b>Clinical Summary & Observations:</b>", styles['Heading3']))
        story.append(Spacer(1, 5))
        story.append(Paragraph(payload.summary_text, styles['Normal']))
        
        # Build document structure layout
        doc.build(story)
        buffer.seek(0)
        
        return StreamingResponse(
            buffer,
            media_type="application/pdf",
            headers={"Content-Disposition": "attachment; filename=clinician_summary.pdf"}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PDF compiler factory failure: {str(e)}")