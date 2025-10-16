OVERVIEW

Sankalp is an intelligent application designed to automate local government services in Kerala. It leverages AI-driven chatbots and a user-friendly interface to assist citizens with scheme inquiries, certificate applications, and complaint drafting, all in Malayalam and English.
The system simplifies interactions between citizens and government offices while reducing manual paperwork and improving service efficiency.
Features

1. Scheme Inquiry Bot

Based on RAG + LLM architecture.
Answers user queries about government schemes using uploaded PDFs.

2. Certificate Application Bot

Guides users interactively for Birth, Death, Income, and Land certificates.
Supports two-level verification (Clerk approval → Admin finalization).

3. Complaint Drafting Bot

Helps users draft formal complaints by asking follow-up questions.
Generates structured complaints ready for submission to authorities.

4. Multilingual Support

Users can interact in Malayalam or English, including voice input.

5. Admin Functionalities

Upload new scheme PDFs.
Track certificate applications in real time.
Heirarchical verification levels.


ARCHITECTURE

User → Flutter App → Flask Backend → SQLite DB
           │
           ├─ RAG-based Scheme Bot
           ├─ AI Agent Certificate Bot
           └─ Complaint Drafting Bot

Frontend: Flutter (cross-platform, mobile-friendly)
Backend: Flask (Python)
Database: SQLite
AI/ML: LLM + RAG for document-based queries
Vector Database: Chromadb
Speech-to-Text: Supports Malayalam voice input

TECH STACK

Frontend: Flutter
Backend: Python Flask
Database: SQLite
Vector Database: Chromadb
AI & NLP: llama-3.3-70b-versatile, RAG, Groq API (LLM Inference)
Voice Processing: Google Speech-to-Text API
Frameworks: Langchain  
Other Tools: Python-dotenv, PDF librariesInstallation

INSTALLATION

1. Clone the repository:
git clone https://github.com/Noel-02/Sankalp-App.git
cd Sankalp

2. Create a virtual environment (Python backend):
python -m venv venv
venv\Scripts\activate      # Windows
source venv/bin/activate   # Linux / Mac

3. Install dependencies:
pip install -r requirements.txt

4. Run the Flask backend:
python app.py

5.Open Flutter frontend in VS Code / Android Studio and run the app on an emulator or device.
