---
created: 2026-06-08 11:36:45
tags: [engram, bugfix]
engram_id: 1371
type: bugfix
---

# Fixed hashline.ps1 status/prune crash on Object[]

**What**: Reparado bug en hashline.ps1 donde `status` y `prune` actions crasheaban con `Method invocation failed because [System.Object[]] does not contain a method named 'op_Addition'`.

**Why**: `$db.files.PSObject.Properties` en hashtables itera propiedades intrínsecas (`Count`, `Keys`, `Values`, ...) además de las entries reales. Al llegar a `Values`, `$f.Value.total_lines` devuelve un array Object[] con todos los total_lines de todos los archivos (PowerShell member-access-on-collection feature), que no se puede sumar con `+=`.

**Where**: `scripts/editing/hashline.ps1` — líneas 257-263 (status action) y línea 292 (prune action).

**Learned**:
- `$hashtable.PSObject.Properties` incluye propiedades intrínsecas del tipo `OrderedHashtable` (Count, Keys, Values, etc.). No es equivalente a `$hashtable.GetEnumerator()` que solo da las key-value pairs reales.
- PowerShell hace "member access enumeration": acceder a una propiedad en una colección devuelve un array de esa propiedad de todos los elementos.
- La solución definitiva es usar `.GetEnumerator()` en vez de `.PSObject.Properties` para iterar hashtables.

---
*Imported from Engram on 2026-09-06*
