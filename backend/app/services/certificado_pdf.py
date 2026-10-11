"""Generación del PDF del certificado de voluntariado (con QR de verificación)."""

import io
from datetime import datetime

import qrcode
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import cm
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

VERDE = HexColor("#0E7C66")
VERDE_OSCURO = HexColor("#0B5D4E")
GRIS = HexColor("#333333")


def generar_pdf(
    *,
    nombre: str,
    horas: float,
    codigo: str,
    fecha: datetime,
) -> bytes:
    buffer = io.BytesIO()
    ancho, alto = landscape(A4)
    c = canvas.Canvas(buffer, pagesize=(ancho, alto))

    c.setStrokeColor(VERDE)
    c.setLineWidth(6)
    c.rect(1 * cm, 1 * cm, ancho - 2 * cm, alto - 2 * cm)
    c.setLineWidth(1)
    c.rect(1.3 * cm, 1.3 * cm, ancho - 2.6 * cm, alto - 2.6 * cm)

    c.setFillColor(VERDE)
    c.setFont("Helvetica-Bold", 30)
    c.drawCentredString(ancho / 2, alto - 4.2 * cm, "Certificado de Voluntariado")

    c.setFillColor(GRIS)
    c.setFont("Helvetica", 14)
    c.drawCentredString(
        ancho / 2, alto - 5.6 * cm, "NexoIA · Voluntariado universitario UCN"
    )

    c.setFont("Helvetica", 15)
    c.drawCentredString(ancho / 2, alto - 7.4 * cm, "Se otorga el presente certificado a")

    c.setFillColor(VERDE_OSCURO)
    c.setFont("Helvetica-Bold", 28)
    c.drawCentredString(ancho / 2, alto - 9.2 * cm, nombre)

    c.setFillColor(GRIS)
    c.setFont("Helvetica", 15)
    c.drawCentredString(
        ancho / 2,
        alto - 10.8 * cm,
        f"por haber completado {horas:.0f} horas de servicio voluntario.",
    )

    qr = qrcode.QRCode(box_size=8, border=2)
    qr.add_data(codigo)
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color="black", back_color="white").get_image()
    c.drawImage(
        ImageReader(qr_img), 2.4 * cm, 2.2 * cm, width=3.2 * cm, height=3.2 * cm
    )

    c.setFont("Helvetica", 10)
    c.drawString(6.2 * cm, 4.4 * cm, f"Código de verificación: {codigo}")
    c.drawString(
        6.2 * cm, 3.6 * cm, f"Fecha: {fecha.strftime('%d/%m/%Y')}"
    )
    c.drawRightString(
        ancho - 2.4 * cm, 3.6 * cm, "Verificable en el panel NexoIA"
    )

    c.showPage()
    c.save()
    return buffer.getvalue()
