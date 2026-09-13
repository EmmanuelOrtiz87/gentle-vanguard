---
created: 2026-06-11 02:51:26
tags: [engram, bugfix]
engram_id: 1385
type: bugfix
---

# GitHub token expuesto en .session/engram-rag/_export-tmp.json

**What**: Secretlint encontró un GitHub Token (`ghp_<redacted-rotado>` — ver nota) en .session/engram-rag/_export-tmp.json línea 12087. El archivo NO está trackeado por git (.gitignore ya tiene .session/) pero existe localmente con un token real.

**Why**: Engram RAG export generó un archivo JSON temporal que contenía un token de GitHub incrustado en datos de sesión.

**Where**: .session/engram-rag/_export-tmp.json (local, no trackeado), .secretlintignore (nuevo), .secretlintrc.json (actualizado con ignores)

**Learned**:
- .gitignore no es suficiente — secretlint escanea archivos locales no trackeados también
- Siempre agregar runtime dirs a secretlint ignores
- El token debe ser ROTADO en GitHub Settings → Developer settings → Personal access tokens
- Rotación: https://github.com/settings/tokens

---
*Imported from Engram on 2026-09-06*
