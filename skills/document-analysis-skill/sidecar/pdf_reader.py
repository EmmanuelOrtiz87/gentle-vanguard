import os
from typing import Any

try:
    import fitz; HAS_FITZ = True
except ImportError: HAS_FITZ = False
try:
    from PIL import Image; import io; HAS_PIL = True
except ImportError: HAS_PIL = False

def extract_text(path):
    if not HAS_FITZ: raise ImportError("PyMuPDF (fitz) is required")
    doc = fitz.open(path)
    text = "".join(page.get_text("text") + "\n" for page in doc)
    doc.close(); return text.strip()

def extract_tables(path):
    if not HAS_FITZ: raise ImportError("PyMuPDF (fitz) is required")
    doc = fitz.open(path); tables = []
    for page_num in range(len(doc)):
        page = doc[page_num]
        for t in page.find_tables():
            rows = [[str(cell).strip() if cell else "" for cell in row] for row in t.extract()]
            tables.append({"page": page_num + 1, "rows": rows, "row_count": len(rows), "col_count": len(rows[0]) if rows else 0})
    doc.close(); return tables

def extract_images(path):
    if not HAS_FITZ: raise ImportError("PyMuPDF (fitz) is required")
    doc = fitz.open(path); images = []
    for page_num in range(len(doc)):
        for img in doc[page_num].get_images(full=True):
            bi = doc.extract_image(img[0])
            images.append({"xref": img[0], "page": page_num + 1, "index": img[1] if len(img) > 1 else 0,
                "width": bi.get("width"), "height": bi.get("height"), "ext": bi.get("ext"),
                "size_bytes": len(bi.get("image", b"")) if bi.get("image") else 0})
    doc.close(); return images

def extract_outlines(path):
    if not HAS_FITZ: raise ImportError("PyMuPDF (fitz) is required")
    return [{"level": item[0], "title": item[1], "page": item[2]} for item in fitz.open(path).get_toc()]

def extract_metadata(path):
    if not HAS_FITZ: raise ImportError("PyMuPDF (fitz) is required")
    doc = fitz.open(path); meta = doc.metadata or {}
    result = {"title": meta.get("title", ""), "author": meta.get("author", ""), "subject": meta.get("subject", ""),
        "keywords": meta.get("keywords", ""), "producer": meta.get("producer", ""), "creator": meta.get("creator", ""),
        "creation_date": meta.get("creationDate", ""), "modification_date": meta.get("modDate", ""),
        "page_count": len(doc), "file_size": os.path.getsize(path), "is_encrypted": doc.is_encrypted}
    doc.close(); return result

def is_scanned(path):
    if not HAS_FITZ: return False
    doc = fitz.open(path)
    total = sum(len(page.get_text("text").strip()) for page in doc)
    doc.close(); return total < 100

def extract_text_with_ocr(path, lang="spa"):
    if not HAS_FITZ: raise ImportError("PyMuPDF (fitz) is required")
    import subprocess, tempfile
    doc = fitz.open(path); full_text = ""
    for page_num in range(len(doc)):
        page = doc[page_num]; text = page.get_text("text").strip()
        if text: full_text += text + "\n"; continue
        pix = page.get_pixmap(dpi=300); img_bytes = pix.tobytes("png")
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp.write(img_bytes); tmp_path = tmp.name
        try:
            result = subprocess.run(["tesseract", tmp_path, "stdout", "-l", lang], capture_output=True, text=True, timeout=30)
            if result.returncode == 0: full_text += result.stdout.strip() + "\n"
        except Exception: pass
        finally:
            try: os.unlink(tmp_path)
            except Exception: pass
    doc.close(); return full_text.strip()

def read_pdf_full(path):
    if not HAS_FITZ: raise ImportError("PyMuPDF (fitz) is required")
    doc = fitz.open(path)
    pages, table_list, image_list, full_text = [], [], [], ""
    scanned = is_scanned(path)
    for page_num in range(len(doc)):
        page = doc[page_num]; text = page.get_text("text"); full_text += text
        pages.append({"page_number": page_num + 1, "text": text, "char_count": len(text)})
        for t in page.find_tables():
            rows = [[str(cell).strip() if cell else "" for cell in row] for row in t.extract()]
            table_list.append({"page": page_num + 1, "rows": rows, "row_count": len(rows), "col_count": len(rows[0]) if rows else 0})
        for img_index, img in enumerate(page.get_images(full=True)):
            bi = doc.extract_image(img[0])
            image_list.append({"xref": img[0], "page": page_num + 1, "index": img_index,
                "width": bi.get("width"), "height": bi.get("height"), "ext": bi.get("ext")})
    outlines = [{"level": item[0], "title": item[1], "page": item[2]} for item in doc.get_toc()]
    meta = doc.metadata or {}; doc.close()
    return {"content": full_text, "is_scanned": scanned,
        "metadata": {"title": meta.get("title", ""), "author": meta.get("author", ""), "subject": meta.get("subject", ""),
            "keywords": meta.get("keywords", ""), "producer": meta.get("producer", ""), "creator": meta.get("creator", ""),
            "page_count": len(pages), "file_size": os.path.getsize(path)},
        "structure": {"pages": pages, "outlines": outlines}, "tables": table_list, "images": image_list, "errors": []}
