import csv
import io
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet

class ExportService:
    def __init__(self):
        pass

    def generate_csv(self, data: list, headers: list) -> str:
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=headers)
        writer.writeheader()
        writer.writerows(data)
        return output.getvalue()

    def generate_pdf(self, title: str, insights: list, daily_data: list) -> bytes:
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter)
        elements = []
        styles = getSampleStyleSheet()

        # Title
        elements.append(Paragraph(f"<b>{title}</b>", styles['Title']))
        elements.append(Spacer(1, 20))

        # Insights Section
        elements.append(Paragraph("<b>AI Insights & Recommendations</b>", styles['Heading2']))
        for insight in insights:
            elements.append(Paragraph(f"• {insight}", styles['Normal']))
        elements.append(Spacer(1, 20))

        # Data Table
        if daily_data:
            elements.append(Paragraph("<b>Daily Traffic Data</b>", styles['Heading2']))
            table_data = [["Date", "Entries", "Exits"]]
            for d in daily_data:
                table_data.append([str(d.get("date", "")), str(d.get("entries", 0)), str(d.get("exits", 0))])
                
            t = Table(table_data)
            t.setStyle(TableStyle([
                ('BACKGROUND', (0,0), (-1,0), colors.grey),
                ('TEXTCOLOR', (0,0), (-1,0), colors.whitesmoke),
                ('ALIGN', (0,0), (-1,-1), 'CENTER'),
                ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0,0), (-1,0), 12),
                ('BACKGROUND', (0,1), (-1,-1), colors.beige),
                ('GRID', (0,0), (-1,-1), 1, colors.black)
            ]))
            elements.append(t)

        doc.build(elements)
        pdf_bytes = buffer.getvalue()
        buffer.close()
        return pdf_bytes
