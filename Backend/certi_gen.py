from flask import Flask, request, jsonify, send_file, Blueprint
from flask_cors import CORS
import random
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.platypus import Paragraph, Frame
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.enums import TA_JUSTIFY
from PIL import Image
import sqlite3
import os

# app = Flask(__name__)
# CORS(app)

certi_gen = Blueprint('certi_gen', __name__)
CORS(certi_gen)

def get_db_connection():
    conn = sqlite3.connect('certificates.db')
    conn.row_factory = sqlite3.Row
    return conn

def get_certificate_data(application_id, certificate_type):
    print(f"Fetching certificate data for application_id: {application_id}, certificate_type: {certificate_type}")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Applications WHERE application_id = ? AND certificate_type = ?", 
                   (application_id, certificate_type))
    certificate_data = cursor.fetchone()
    conn.close()
    print("Fetched data:", dict(certificate_data) if certificate_data else "None")
    return certificate_data

def store_pdf_in_db(application_id, certificate_type, pdf_file):
    print(f"Storing PDF path in DB for application_id: {application_id}, certificate_type: {certificate_type}")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(""" 
        UPDATE Applications
        SET pdf_file = ?
        WHERE application_id = ? AND certificate_type = ?
    """, (pdf_file, application_id, certificate_type))
    conn.commit()
    conn.close()
    print("PDF path stored successfully")

def create_base_pdf(buffer, key_number):
    pdf = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    # Add background logo
    logo_path = "govt.jpeg"
    image = Image.open(logo_path)
    image = image.convert("RGBA")
    data = image.getdata()
    new_data = [(item[0], item[1], item[2], 100) for item in data]
    image.putdata(new_data)
    image.save("light_govt.png")

    # Center logo
    logo_width = 300
    logo_height = 180
    pdf.drawImage("light_govt.png", (width - logo_width) / 2, (height - logo_height) / 2,
                  width=logo_width, height=logo_height, mask='auto')

    # Key number
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawString(50, height - 50, f"KEYNO: {key_number}")

    # Top-left logo
    logo_width_small = 50
    logo_height_small = 50
    pdf.drawImage("light_govt.png", 50, height - logo_height_small - 50,
                  width=logo_width_small, height=logo_height_small, mask='auto')

    # Header
    pdf.setFont("Helvetica-Bold", 14)
    pdf.drawCentredString(width / 2, height - 50, "GOVERNMENT OF KERALA")

    return pdf, width, height

def add_justified_paragraph(pdf, width, height, text):
    styles = getSampleStyleSheet()
    style = styles["Normal"]
    style.fontName = "Helvetica"
    style.fontSize = 10
    style.leading = 12
    style.alignment = TA_JUSTIFY

    p = Paragraph(text, style)
    frame = Frame(50, height - 220, width - 100, 60, leftPadding=0, bottomPadding=0, rightPadding=0, topPadding=0)
    frame.addFromList([p], pdf)

@certi_gen.route('/generate_pdf', methods=['POST'])
def generate_pdf():
    data = request.get_json()
    print("Received request data:", data)    
    if not data or not isinstance(data, dict):
        return jsonify({"error": "Invalid or missing JSON data"}), 400

    application_id = data.get('application_id')
    certificate_type = data.get('certificate_type')
    print(f"Processing PDF generation for application_id: {application_id}, certificate_type: {certificate_type}")
    if not application_id or not certificate_type:
        return jsonify({"error": "Missing required fields"}), 400

    # Create PDF buffer and base template
    buffer = BytesIO()
    key_number = random.randint(100000, 999999)
    pdf, width, height = create_base_pdf(buffer, key_number)

    # Initialize fields as an empty list
    fields = []

    # Certificate type specific content
    pdf.setFont("Helvetica-Bold", 16)
    if certificate_type == "Birth Certificate":
        pdf.drawCentredString(width / 2, height - 120, "BIRTH CERTIFICATE")
        common_text = ("(Issued under Section 12 of the Registration of Births and Deaths Acts, 1969 and Rule 8 of the Kerala "
                      "Registration of Births and Deaths Rules, 1999) This is to certify that the following information has been "
                      "taken from the original record of birth which is the register for (local area/local body) "
                      "Thiruvananthapuram Corporation of Taluk Thiruvananthapuram of District Thiruvananthapuram of State Kerala.")
        add_justified_paragraph(pdf, width, height, common_text)

        pdf.setFont("Helvetica", 10)
        fields = [
            ('Name', data.get('full_name')),
            ("Father's Name", data.get('fathers_name')),
            ("Mother's Name", data.get('mothers_name')),
            ('Date of Birth', data.get('date_of_birth')),
            ('Place of Birth', data.get('place_of_birth'))
        ]
        
    elif certificate_type == "Death Certificate":
        pdf.drawCentredString(width / 2, height - 120, "DEATH CERTIFICATE")

        # Add the justified paragraph (common for death certificate)
        paragraph = (
            "(Issued under Section 12 of the Registration of Births and Deaths Acts, 1969 and Rule 8 of the Kerala "
            "Registration of Births and Deaths Rules, 1999) This is to certify that the following information has been "
            "taken from the original record of death which is the register for (local area/local body) "
            "Thiruvananthapuram Corporation of Taluk Thiruvananthapuram of District Thiruvananthapuram of State Kerala."
        )

        # Style for the paragraph
        styles = getSampleStyleSheet()
        style = styles["Normal"]
        style.fontName = "Helvetica"
        style.fontSize = 10
        style.leading = 12
        style.alignment = TA_JUSTIFY

        # Create and draw the paragraph
        p = Paragraph(paragraph, style)
        frame = Frame(50, height - 220, width - 100, 60, leftPadding=0, bottomPadding=0, rightPadding=0, topPadding=0)
        frame.addFromList([p], pdf)

        pdf.setFont("Helvetica", 10)
        fields = [
            ('Name', data.get('name', 'N/A')),
            ('Date of Death', data.get('date_of_death', 'N/A')),
            ('Place of Death', data.get('place_of_death', 'N/A')),
            ('Cause of Death', data.get('cause_of_death', 'N/A'))
        ]
        


    elif certificate_type == "Income Certificate":
        pdf.drawCentredString(width / 2, height - 70, "INCOME CERTIFICATE")
        pdf.setFont("Helvetica", 10)
        pdf.drawString(50, height - 140, "Certified that the Annual Family Income of the person with the details mentioned below")
        
        fields = [
            ('Name', data.get('name')),
            ('Annual Income', data.get('annual_income')),
            ('Source of Income', data.get('source_of_income')),
            ('Address', data.get('address'))
        ]

    elif certificate_type == "Land Certificate":
        pdf.drawCentredString(width / 2, height - 70, "LAND POSSESSION CERTIFICATE")
        pdf.setFont("Helvetica", 10)
        
        fields = [
            ('Owner Name', data.get('owner_name')),
            ('Property Address', data.get('property_address')),
            ('Market Value', data.get('market_value')),
            ('Area in Sq. Ft', data.get('area_sqft')),
            ('Survey Number', data.get('survey_number'))
        ]
    print("Fields:", fields)
    # Draw fields (only if fields is not empty)
    if fields:
        for i, (label, value) in enumerate(fields):
            y_position = height - 300 - (i * 20) if certificate_type == "Birth Certificate" or "Death Certificate" else height - 200 - (i * 20)
            pdf.drawString(50, y_position, f"{label}: {value}")

    # Add footer
    pdf.drawString(50, 50, "NB: This certificate is for demonstration purposes.")

    pdf.showPage()
    pdf.save()

    # Save PDF to filesystem
    save_path = r"C:\Users\Athul M Nair\Desktop\gen"
    os.makedirs(save_path, exist_ok=True)
    file_name = f"{certificate_type.replace(' ', '')}certificate{application_id}.pdf"
    pdf_file_path = os.path.join(save_path, file_name)

    with open(pdf_file_path, 'wb') as f:
        f.write(buffer.getvalue())

    store_pdf_in_db(application_id, certificate_type, pdf_file_path)

    return jsonify({
        "message": "PDF generated and saved successfully",
        "file_path": pdf_file_path
    }), 200

@certi_gen.route('/get_pdf', methods=['POST'])
def get_pdf():
    data = request.get_json()
    application_id = data.get('application_id')
    certificate_type = data.get('certificate_type')

    if not application_id or not certificate_type:
        return jsonify({"error": "application_id and certificate_type are required"}), 400

    save_path = r"C:\Users\Athul M Nair\Desktop\gen"
    file_name = f"{certificate_type.replace(' ', '')}certificate{application_id}.pdf"
    pdf_file_path = os.path.join(save_path, file_name)

    if not os.path.exists(pdf_file_path):
        return jsonify({"error": "PDF not found"}), 404

    return send_file(
        pdf_file_path,
        as_attachment=True,
        download_name=file_name,
        mimetype='application/pdf'
    )

