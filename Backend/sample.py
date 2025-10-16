from flask import Flask, request, jsonify, Blueprint
from flask_cors import CORS
import os
import uuid  # For generating unique session IDs
from langchain_community.vectorstores import Chroma
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings.fastembed import FastEmbedEmbeddings
from langchain_community.document_loaders import PDFPlumberLoader
from langchain.prompts import PromptTemplate
from groq import Groq
from datetime import datetime
from db_utils import insert_application_logs, get_chat_history


# Initialize the Groq client

folder_path = "db"

embedding = FastEmbedEmbeddings()

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1024, chunk_overlap=80, length_function=len, is_separator_regex=False
)

complaint_prompt = PromptTemplate.from_template(
    """ 
    You are an AI assistant specializing in answering questions about various government schemes.  
Use the provided context to answer the user's query.  

If the context contains the relevant information, respond concisely and accurately based on the context.  
If the context does not include the necessary information to answer the query, reply with:  
"Sorry, the required information is not available in the provided context."  

Here is your task:  

**Query:** {input}  
**Context:** {context}  

"""
)

sample = Blueprint('sample', __name__)
CORS(sample)

# Create a Flask app
# app = Flask(__name__)
# CORS(app)

@sample.route("/ask_pdf", methods=["POST"])
def askPDFPost():
    try:
        print("Post /ask_pdf called")
        json_content = request.json
        query = json_content.get("query")

        if not query:
            return {"error": "Query cannot be empty."}, 400

        print(f"Query received: {query}")

        # Load the vector store to retrieve relevant documents
        print("Loading vector store")
        vector_store = Chroma(persist_directory=folder_path, embedding_function=embedding)

        # Retrieve relevant documents based on the query
        print("Retrieving relevant documents")
        retriever = vector_store.as_retriever(
            search_type="similarity_score_threshold",
            search_kwargs={
                "k": 5,  # Number of documents to retrieve
                "score_threshold": 0.1,
            }
        )
        docs = retriever.get_relevant_documents(query)
        print(f"Found {len(docs)} relevant documents")

        # Use Groq to process the query with retrieved context
        context = "\n".join(doc.page_content for doc in docs)
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": f"{query}\nContext: {context}",
                }
            ],
            model="llama-3.3-70b-versatile",
        )

        groq_response = chat_completion.choices[0].message.content
        print(f"Groq response: {groq_response}")

        sources = [{"source": doc.metadata.get("source"), "page_content": doc.page_content} for doc in docs]

        return jsonify({"answer": groq_response, "sources": sources}), 200

    except Exception as e:
        print(f"Error in askPDFPost: {e}")
        return {"error": f"An error occurred: {e}"}, 500

@sample.route("/pdf", methods=["POST"])
def pdfPost():
    try:
        # Get the uploaded file
        file = request.files["file"]
        file_name = file.filename

        # Define save location and save the file
        save_file = os.path.join("pdf", file_name)
        os.makedirs("pdf", exist_ok=True)  # Ensure the directory exists
        file.save(save_file)
        print(f"File saved: {save_file}")

        # Load and split the PDF
        loader = PDFPlumberLoader(save_file)
        docs = loader.load_and_split()
        print(f"Number of documents: {len(docs)}")

        # Split documents into chunks
        chunks = text_splitter.split_documents(docs)
        print(f"Number of chunks: {len(chunks)}")

        # Store chunks in Chroma vector store
        vector_store = Chroma.from_documents(
            documents=chunks,
            embedding=embedding,
            persist_directory=folder_path
        )
        vector_store.persist()
        print("Vector store persisted successfully.")

        response = {
            "status": "Successfully Uploaded",
            "filename": file_name,
            "doc_len": len(docs),
            "chunks": len(chunks),
        }
        return response, 200

    except Exception as e:
        print(f"Error in pdfPost: {e}")
        return {"error": str(e)}, 500

