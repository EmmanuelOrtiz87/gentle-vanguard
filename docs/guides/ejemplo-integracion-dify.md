# Ejemplo de integracin Dify.io en Foundation

Este instructivo muestra cmo conectar Foundation a Dify.io usando la arquitectura estndar.

---

## 1. Configuracin del proveedor en cloud-agents.local.json

Copia el bloque de ejemplo desde config/cloud-agents.local.example y edtalo as:

```
{
  "providers": {
    "dify": {
      "enabled": true,
      "description": "Dify AI - Custom AI platform",
      "endpoint": "https://api.dify.ai/v1/chat/completions",
      "model": "dify-model",
      "api_key_env": "DIFY_API_KEY"
    }
  }
}
```

---

## 2. Carga tu API key

Crea un archivo `.env.local` (o usa el ejemplo `.env.local.example`) en la raz del repo:

```
DIFY_API_KEY=pon_aqui_tu_api_key
```

O bien, exporta la variable en tu terminal:

```powershell
$env:DIFY_API_KEY = "pon_aqui_tu_api_key"
```

---

## 3. Prueba la conexin

```powershell
cd workspace-foundation
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider dify -TestConnection
```

---

## 4. Uso manual

- Ejecutar un comando:
  ```powershell
  .\scripts\utilities\invoke-cloud-agent.ps1 -Provider dify -Command "Cul es la capital de Francia?"
  ```
- Modo estricto (automatizacin):
  ```powershell
  .\scripts\utilities\invoke-cloud-agent.ps1 -Provider dify -StrictJson -Command "return JSON"
  ```
- Modo interactivo:
  ```powershell
  .\scripts\utilities\invoke-cloud-agent.ps1 -Provider dify -Interactive
  ```

---

## Notas
- Nunca pongas la API key en archivos versionados.
- Puedes tener mltiples proveedores configurados y alternar con el flag `-Provider`.
- Si el endpoint requiere parmetros adicionales, consulta la documentacin de Dify.io.

---

**ltima actualizacin:** 2026-04-20
