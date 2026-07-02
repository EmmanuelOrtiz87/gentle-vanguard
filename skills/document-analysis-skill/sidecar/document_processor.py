import os, re, hashlib
from typing import Any
from office_reader import read_docx, read_xlsx, read_pptx, read_pdf, read_txt, read_csv, read_markdown, read_xml, read_json

def detect_type(path):
    ext = path.lower().rsplit(".", 1)[-1] if "." in path else ""
    return {"docx": "word", "doc": "word", "xlsx": "excel", "xls": "excel", "pptx": "powerpoint", "ppt": "powerpoint",
        "pdf": "pdf", "txt": "text", "csv": "csv", "md": "markdown", "markdown": "markdown",
        "xml": "xml", "json": "json", "html": "html", "htm": "html",
        "png": "image", "jpg": "image", "jpeg": "image", "tiff": "image", "tif": "image",
        "bmp": "image", "webp": "image", "gif": "image",
        "rtf": "rtf", "odt": "odt", "ods": "ods", "odp": "odp"}.get(ext, "unknown")

def process_document(path):
    doc_type = detect_type(path)
    readers = {"word": read_docx, "excel": read_xlsx, "powerpoint": read_pptx, "pdf": read_pdf,
        "text": read_txt, "csv": read_csv, "markdown": read_markdown, "xml": read_xml, "json": read_json}
    reader = readers.get(doc_type)
    if reader is None: return {"error": f"No reader available for type: {doc_type}", "type": doc_type, "path": path}
    try:
        result = reader(path); result["doc_type"] = doc_type; return result
    except Exception as e: return {"error": str(e), "type": doc_type, "path": path}

def extract_text(path):
    result = process_document(path)
    if "error" in result: return ""
    content = result.get("content") or result.get("text") or ""
    if isinstance(content, list): return " ".join(str(c) for c in content)
    if isinstance(content, dict):
        parts = []
        for key, value in content.items():
            if isinstance(value, str): parts.append(value)
            elif isinstance(value, list): parts.append(" ".join(str(v) for v in value))
        return " ".join(parts)
    return str(content)

def extract_metadata(path):
    result = process_document(path)
    if "error" in result: return {"path": path, "error": result["error"]}
    metadata = result.get("metadata", {})
    if os.path.exists(path):
        import datetime; s = os.stat(path)
        metadata.update({"file_size": s.st_size, "created": datetime.datetime.fromtimestamp(s.st_ctime).isoformat(),
            "modified": datetime.datetime.fromtimestamp(s.st_mtime).isoformat(),
            "file_name": os.path.basename(path), "file_extension": path.rsplit(".", 1)[-1].lower() if "." in path else ""})
    metadata["md5"] = _compute_md5(path)
    return metadata

def _compute_md5(path):
    try:
        h = hashlib.md5()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""): h.update(chunk)
        return h.hexdigest()
    except Exception: return ""

def chunk_document(text, chunk_size=1000, overlap=200):
    if not text: return []
    if overlap >= chunk_size: overlap = chunk_size // 4
    chunks, start, index = [], 0, 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        if end < len(text):
            last_space = text.rfind(" ", start, end)
            if last_space > start: end = last_space
        chunks.append({"index": index, "text": text[start:end], "start_char": start, "end_char": end, "size": end - start})
        index += 1; start = max(0, end - overlap)
    return chunks

_DOC_CLASSIFIERS = {
    "rfp": r"(?i)\b(request\s+for\s+proposal|rfp|licitaci[oó]n|concurso\s+p[uú]blico)\b",
    "proposal": r"(?i)\b(propuesta\s+t[eé]cnica|proposal|oferta\s+econ[oó]mica|cotizaci[oó]n)\b",
    "timesheet": r"(?i)\b(hours?\s+worked|timesheet|horas\s+trabajadas|registro\s+horario)\b",
    "contract": r"(?i)\b(contrato|contract|cl[aá]usula|acuerdo\s+legal)\b",
    "invoice": r"(?i)\b(invoice|factura|recibo|cuenta\s+de\s+cobro)\b",
    "report": r"(?i)\b(informe|report|memoria|balance|resultados)\b",
    "technical_document": r"(?i)\b(manual\s+t[eé]cnico|technical\s+documentation|especificaci[oó]n|arquitectura)\b",
    "meeting_minutes": r"(?i)\b(acta\s+de\s+reuni[oó]n|meeting\s+minutes|minuta|acuerdos)\b",
}

def classify_document(content):
    if not content: return "unknown"
    scores = {doc_type: len(re.findall(pattern, content)) for doc_type, pattern in _DOC_CLASSIFIERS.items()}
    if not scores or max(scores.values()) == 0: return "general"
    return max(scores, key=scores.get)

def detect_language(text):
    try:
        counts = {"es": len(re.findall(r"[áéíóúüñ¿¡]", text.lower())),
            "pt": len(re.findall(r"[áâãàçéêíóôõú]", text.lower())),
            "fr": len(re.findall(r"[éèêëàâùûüçôöîï]", text.lower())),
            "de": len(re.findall(r"[äöüß]", text.lower()))}
        total = len(text)
        if total == 0: return None
        scores = [(lang, count / total) for lang, count in counts.items()]
        scores.sort(key=lambda x: x[1], reverse=True)
        return scores[0][0] if scores[0][1] > 0.001 else "en"
    except Exception: return None
