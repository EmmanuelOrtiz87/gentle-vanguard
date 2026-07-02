import os, subprocess, tempfile
from typing import Any

try:
    from PIL import Image; from PIL.ExifTags import TAGS; HAS_PIL = True
except ImportError: HAS_PIL = False

SUPPORTED_FORMATS = {".png", ".jpg", ".jpeg", ".tiff", ".tif", ".bmp", ".webp"}

def read_image(path):
    if not HAS_PIL: raise ImportError("Pillow is required")
    ext = os.path.splitext(path)[1].lower()
    if ext not in SUPPORTED_FORMATS: raise ValueError(f"Unsupported image format: {ext}. Supported: {SUPPORTED_FORMATS}")
    img = Image.open(path)
    exif_data = {}
    if hasattr(img, "_getexif") and img._getexif():
        for tag_id, value in img._getexif().items():
            exif_data[TAGS.get(tag_id, tag_id)] = str(value)
    return {"content": "", "metadata": {"format": img.format, "mode": img.mode, "width": img.width, "height": img.height,
        "file_size": os.path.getsize(path), "dpi": img.info.get("dpi", None), "exif": exif_data},
        "structure": {}, "tables": [], "images": [{"path": path, "width": img.width, "height": img.height, "format": img.format}], "errors": []}

def extract_text_from_image(path, lang="spa"):
    try:
        result = subprocess.run(["tesseract", path, "stdout", "-l", lang], capture_output=True, text=True, timeout=60)
        return result.stdout.strip() if result.returncode == 0 else ""
    except (FileNotFoundError, subprocess.TimeoutExpired, Exception): return ""

def extract_tables_from_image(path):
    ocr_text = extract_text_from_image(path, "spa+eng")
    if not ocr_text: return []
    lines = [l.strip() for l in ocr_text.splitlines() if l.strip()]
    rows = [[c.strip() for c in line.split("|")] if "|" in line else [line] for line in lines]
    return [{"source": "ocr", "path": path, "rows": rows, "row_count": len(rows), "col_count": max(len(r) for r in rows) if rows else 0}] if rows else []

def get_image_metadata(path):
    if not HAS_PIL: raise ImportError("Pillow is required")
    img = Image.open(path)
    exif_data = {}
    if hasattr(img, "_getexif") and img._getexif():
        for tag_id, value in img._getexif().items():
            exif_data[TAGS.get(tag_id, tag_id)] = str(value)
    return {"format": img.format, "mode": img.mode, "width": img.width, "height": img.height,
        "aspect_ratio": round(img.width / img.height, 4) if img.height > 0 else 0,
        "file_size": os.path.getsize(path), "dpi": img.info.get("dpi", None), "exif": exif_data,
        "is_animated": getattr(img, "is_animated", False), "frames": getattr(img, "n_frames", 1) if hasattr(img, "n_frames") else 1}
