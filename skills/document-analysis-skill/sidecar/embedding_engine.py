import math, hashlib, os
from collections import OrderedDict
from typing import Any

try:
    from sentence_transformers import SentenceTransformer; HAS_SENTENCE_TRANSFORMERS = True
except ImportError: HAS_SENTENCE_TRANSFORMERS = False

from document_processor import extract_text, chunk_document

class LRUCache:
    def __init__(self, capacity=128):
        self.cache = OrderedDict(); self.capacity = capacity
    def get(self, key):
        if key not in self.cache: return None
        self.cache.move_to_end(key); return self.cache[key]
    def put(self, key, value):
        self.cache[key] = value; self.cache.move_to_end(key)
        if len(self.cache) > self.capacity: self.cache.popitem(last=False)
    def clear(self): self.cache.clear()

class EmbeddingEngine:
    def __init__(self):
        self.model = None; self.model_name = ""; self.cache = LRUCache(capacity=256)

    def initialize(self, model_name="all-MiniLM-L6-v2"):
        if not HAS_SENTENCE_TRANSFORMERS: raise ImportError("sentence-transformers is required")
        if self.model is None or self.model_name != model_name:
            self.model = SentenceTransformer(model_name); self.model_name = model_name

    def encode(self, texts):
        if self.model is None: raise RuntimeError("EmbeddingEngine not initialized")
        results, uncached_texts, uncached_indices = [], [], []
        for i, text in enumerate(texts):
            key = hashlib.md5(text.encode("utf-8")).hexdigest()
            cached = self.cache.get(key)
            if cached is not None: results.append((i, cached))
            else: uncached_texts.append(text); uncached_indices.append((i, key))
        if uncached_texts:
            embeddings = self.model.encode(uncached_texts, show_progress_bar=False)
            for idx, (orig_idx, key) in enumerate(uncached_indices):
                self.cache.put(key, embeddings[idx].tolist()); results.append((orig_idx, embeddings[idx].tolist()))
        results.sort(key=lambda x: x[0]); return [r[1] for r in results]

    def encode_document(self, path, chunk_size=500, overlap=100):
        text = extract_text(path)
        chunks = chunk_document(text, chunk_size=chunk_size, overlap=overlap)
        chunk_texts = [c["text"] for c in chunks]
        if not chunk_texts: return []
        embeddings = self.encode(chunk_texts)
        return [{"index": c["index"], "text": c["text"], "start_char": c["start_char"], "end_char": c["end_char"], "embedding": embeddings[i] if i < len(embeddings) else []} for i, c in enumerate(chunks)]

    def similarity(self, query_embedding, embeddings):
        query_norm = math.sqrt(sum(x * x for x in query_embedding))
        if query_norm == 0: return [0.0] * len(embeddings)
        return [sum(a * b for a, b in zip(query_embedding, emb)) / (query_norm * math.sqrt(sum(x * x for x in emb)) + 1e-10) for emb in embeddings]

    def search(self, query, documents, top_k=5):
        query_emb = self.encode([query])[0]
        doc_embs = self.encode(documents)
        scores = self.similarity(query_emb, doc_embs)
        indexed = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
        return [{"index": idx, "text": documents[idx], "score": round(score, 4)} for idx, score in indexed[:top_k]]

    def clear_cache(self): self.cache.clear()
