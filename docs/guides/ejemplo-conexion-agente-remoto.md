# Ejemplo: Conexión a un Agente IA Remoto vía API

Este ejemplo documenta el paso a paso para conectar Foundation (o tu entorno local) a un agente IA externo expuesto vía API, usando solo la URL y la API key.

---

## 1. Crear configuración local de proveedores

Desde PowerShell, en la raíz de workspace-foundation:

```powershell
cd C:\Workspace_local\workspace-foundation
.\scripts\utilities\invoke-cloud-agent.ps1 -Config
```
Selecciona la opción 2 para crear el archivo `config/cloud-agents.local.json`.

---

## 2. Agregar la API Key

**Opción recomendada (producción):**

```powershell
$env:MY_AGENT_APIKEY = "tu_apikey"
```

**Opción desarrollo:**

Crea un archivo `.env.local` en la raíz del repo y agrega:

```
MY_AGENT_APIKEY=tu_apikey
```

---

## 3. Configurar el proveedor en cloud-agents.local.json

Edita `config/cloud-agents.local.json` y agrega tu proveedor personalizado:

```
{
  "providers": {
    "custom": {
      "enabled": true,
      "endpoint": "https://vxhfmjrvbh.execute-api.us-east-1.amazonaws.com/prod/api/agents/18",
      "api_key_env": "MY_AGENT_APIKEY"
    }
  }
}
```

- Si el proveedor no requiere parámetro "model", puedes omitirlo.
- "api_key_env" debe coincidir con el nombre de tu variable de entorno.

---

## 4. Probar la conexión

```powershell
.\scripts\utilities\invoke-cloud-agent.ps1 -Provider custom -TestConnection
```

---

## 5. Uso manual

- Ejecutar un comando:
  ```powershell
  .\scripts\utilities\invoke-cloud-agent.ps1 -Provider custom -Command "¿Cuál es la capital de Francia?"
  ```
- Modo estricto (automatización):
  ```powershell
  .\scripts\utilities\invoke-cloud-agent.ps1 -Provider custom -StrictJson -Command "return JSON"
  ```
- Modo interactivo:
  ```powershell
  .\scripts\utilities\invoke-cloud-agent.ps1 -Interactive
  ```

---

## Notas
- Nunca pongas la API key en archivos versionados.
- Usa variables de entorno o `.env.local` (gitignored).
- Puedes tener múltiples proveedores configurados y alternar con el flag `-Provider`.
- Si el endpoint requiere parámetros adicionales, consulta la documentación del proveedor.

---

**Última actualización:** 2026-04-20
