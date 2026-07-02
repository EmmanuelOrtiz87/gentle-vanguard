import sys, json, logging, traceback, signal
from typing import Any
from document_processor import process_document, chunk_document, classify_document
from office_reader import read_docx, read_xlsx, read_pptx, read_pdf, read_txt, read_csv, read_markdown, read_xml, read_json
from diagram_generator import generate_mermaid, generate_plantuml, render_to_svg
try:
    from document_generator import generate_docx, generate_xlsx, generate_pptx, generate_pdf, generate_markdown
except ImportError:
    generate_docx = generate_xlsx = generate_pptx = generate_pdf = generate_markdown = None
from embedding_engine import EmbeddingEngine
from image_reader import read_image, extract_tables_from_image, extract_text_from_image

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s", stream=sys.stderr)
logger = logging.getLogger("gv-document-analysis")

embedding_engine: EmbeddingEngine | None = None

def handle_ping(cmd: dict) -> dict:
    return {"type": "pong", "id": cmd.get("id")}

def handle_read_document(cmd: dict) -> dict:
    path = cmd.get("path", "")
    options = cmd.get("options", {})
    ext = path.lower().rsplit(".", 1)[-1] if "." in path else ""
    readers = {
        "docx": read_docx, "doc": read_docx, "xlsx": read_xlsx, "xls": read_xlsx,
        "pptx": read_pptx, "ppt": read_pptx, "pdf": read_pdf,
        "txt": read_txt, "csv": read_csv, "md": read_markdown, "markdown": read_markdown,
        "xml": read_xml, "json": read_json,
        "png": lambda p: read_image(p), "jpg": lambda p: read_image(p),
        "jpeg": lambda p: read_image(p), "tiff": lambda p: read_image(p),
        "tif": lambda p: read_image(p), "bmp": lambda p: read_image(p), "webp": lambda p: read_image(p),
    }
    reader = readers.get(ext)
    if reader is None:
        result = process_document(path)
        if result.get("error"):
            return {"type": "error", "id": cmd.get("id"), "error": f"Unsupported format: {ext}", "path": path}
        return {"type": "document", "id": cmd.get("id"), "result": result}
    try:
        if ext in ("png", "jpg", "jpeg", "tiff", "tif", "bmp", "webp"):
            result = reader(path)
            ocr_text = extract_text_from_image(path, options.get("language", "spa"))
            if ocr_text: result["ocr_text"] = ocr_text
            return {"type": "document", "id": cmd.get("id"), "result": result}
        result = reader(path) if ext != "csv" else reader(path, options.get("delimiter", None))
        return {"type": "document", "id": cmd.get("id"), "result": result}
    except Exception as e:
        logger.exception("Error reading document %s", path)
        return {"type": "error", "id": cmd.get("id"), "error": str(e), "path": path}

def handle_read_directory(cmd: dict) -> dict:
    import os, fnmatch
    path = cmd.get("path", ".")
    recursive = cmd.get("recursive", False)
    pattern = cmd.get("pattern", "*")
    results, errors = [], []
    if recursive:
        for root, dirs, files in os.walk(path):
            for f in files:
                if fnmatch.fnmatch(f, pattern):
                    try:
                        r = handle_read_document({"path": os.path.join(root, f), "options": cmd.get("options", {})})
                        results.append(r)
                    except Exception as e: errors.append({"path": os.path.join(root, f), "error": str(e)})
    else:
        for entry in os.listdir(path):
            fpath = os.path.join(path, entry)
            if os.path.isfile(fpath) and fnmatch.fnmatch(entry, pattern):
                try:
                    r = handle_read_document({"path": fpath, "options": cmd.get("options", {})})
                    results.append(r)
                except Exception as e: errors.append({"path": fpath, "error": str(e)})
    return {"type": "directory", "id": cmd.get("id"), "results": results, "errors": errors, "count": len(results)}

def handle_generate_documentation(cmd: dict) -> dict:
    content = cmd.get("content", {})
    fmt = cmd.get("format", "docx")
    template = cmd.get("template", "default")
    generators = {"docx": generate_docx, "xlsx": generate_xlsx, "pptx": generate_pptx, "pdf": generate_pdf, "markdown": generate_markdown, "md": generate_markdown}
    gen = generators.get(fmt)
    if gen is None: return {"type": "error", "id": cmd.get("id"), "error": f"Unsupported format: {fmt}"}
    try:
        if fmt == "pdf": result_bytes = gen(content.get("text", ""), content.get("options", {}))
        elif fmt in ("markdown", "md"): result_bytes = gen(content).encode("utf-8")
        else: result_bytes = gen(content, template)
        import base64
        b64 = base64.b64encode(result_bytes).decode("utf-8")
        return {"type": "documentation", "id": cmd.get("id"), "format": fmt, "data": b64, "size": len(result_bytes)}
    except Exception as e:
        logger.exception("Error generating document")
        return {"type": "error", "id": cmd.get("id"), "error": str(e)}

def handle_generate_diagram(cmd: dict) -> dict:
    description = cmd.get("description", "")
    diagram_type = cmd.get("diagram_type", "flowchart")
    engine = cmd.get("engine", "mermaid")
    try:
        code = generate_plantuml(description, diagram_type) if engine == "plantuml" else generate_mermaid(description, diagram_type)
        svg = render_to_svg(code) if cmd.get("render", False) else None
        return {"type": "diagram", "id": cmd.get("id"), "code": code, "diagram_type": diagram_type, "engine": engine, "svg": svg}
    except Exception as e:
        logger.exception("Error generating diagram")
        return {"type": "error", "id": cmd.get("id"), "error": str(e)}

def handle_get_embeddings(cmd: dict) -> dict:
    global embedding_engine
    texts = cmd.get("texts", [])
    model_name = cmd.get("model", "all-MiniLM-L6-v2")
    try:
        if embedding_engine is None:
            embedding_engine = EmbeddingEngine()
            embedding_engine.initialize(model_name)
        if cmd.get("path"):
            chunks = embedding_engine.encode_document(cmd["path"])
            return {"type": "embeddings", "id": cmd.get("id"), "chunks": chunks, "count": len(chunks)}
        embeddings = embedding_engine.encode(texts)
        return {"type": "embeddings", "id": cmd.get("id"), "embeddings": embeddings, "count": len(embeddings)}
    except Exception as e:
        logger.exception("Error computing embeddings")
        return {"type": "error", "id": cmd.get("id"), "error": str(e)}

COMMAND_MAP = {
    "ping": handle_ping,
    "read_document": handle_read_document,
    "read_directory": handle_read_directory,
    "generate_documentation": handle_generate_documentation,
    "generate_diagram": handle_generate_diagram,
    "get_embeddings": handle_get_embeddings,
}

def process_command(raw: str) -> dict | None:
    raw = raw.strip()
    if not raw: return None
    try: cmd = json.loads(raw)
    except json.JSONDecodeError as e: return {"type": "error", "id": None, "error": f"Invalid JSON: {e}"}
    handler = COMMAND_MAP.get(cmd.get("command", ""))
    if handler is None: return {"type": "error", "id": cmd.get("id"), "error": f"Unknown command: {cmd.get('command')}"}
    return handler(cmd)

def main():
    logger.info("GV Document Analysis sidecar iniciado PID %d", __import__("os").getpid())
    signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))
    signal.signal(signal.SIGINT, lambda s, f: sys.exit(0))
    if "--action" in sys.argv:
        idx = sys.argv.index("--action")
        if idx + 1 < len(sys.argv):
            action = sys.argv[idx + 1]
            payload = {}
            if "--payload" in sys.argv:
                pidx = sys.argv.index("--payload")
                if pidx + 1 < len(sys.argv):
                    try: payload = json.loads(sys.argv[pidx + 1])
                    except json.JSONDecodeError: payload = {"text": sys.argv[pidx + 1]}
            cmd = {"command": action, **payload, "id": "cli"}
            response = process_command(json.dumps(cmd))
            if response: sys.stdout.write(json.dumps(response, ensure_ascii=False) + "\n"); sys.stdout.flush()
        return
    for line in sys.stdin:
        if not line or line.strip() == "": continue
        try:
            response = process_command(line)
            if response is not None: sys.stdout.write(json.dumps(response, ensure_ascii=False) + "\n"); sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({"type": "error", "id": None, "error": str(e), "traceback": traceback.format_exc()}, ensure_ascii=False) + "\n")
            sys.stdout.flush()
    logger.info("GV Document Analysis sidecar finalizado")

if __name__ == "__main__":
    main()
