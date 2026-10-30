import fitz  # PyMuPDF

# Open the PDF
doc = fitz.open("indian.pdf")

# Create or open a text file to write the content
with open("output.txt", "w", encoding="utf-8") as out_file:
    for page_num in range(len(doc)):
        page = doc[page_num]
        text = page.get_text()
        out_file.write(f"--- Page {page_num + 1} ---\n")
        out_file.write(text)
        out_file.write("\n\n")  # Add spacing between pages
