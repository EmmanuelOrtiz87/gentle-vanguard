# Runbook de remediación manual de seguridad

**Audiencia:** propietario del repositorio y administrador de GitHub  
**Alcance:** tareas manuales pendientes de credenciales, controles de GitHub y artefactos
históricos.  
**Última revisión:** 2026-08-29

> **Regla de seguridad:** este documento no contiene secretos. Nunca pegues un PAT, token de
> Telegram o valor detectado en un issue, PR, terminal compartida, captura o log. Los comandos de
> borrado están deliberadamente protegidos por una confirmación interactiva y no deben ejecutarse
> hasta completar la clasificación y comprobar la retención.

## 0. Preparación y límites

1. Trabaja en una sesión de administrador autenticada y en el repositorio correcto.
2. Crea una nota privada de evidencias con fecha, proveedor, **referencia no secreta** (archivo,
   línea, tipo de credencial), acción y resultado.
3. No modifiques código funcional para cerrar este runbook. Los cambios de documentación/configuración
   deben ir en una rama y PR separados.
4. Si un hallazgo parece activo, trátalo como comprometido: revoca primero, rota después y revisa
   el registro de auditoría del proveedor.

### Preflight local (CMD-first, solo lectura)

Desde CMD en la raíz del checkout:

```cmd
git status --short
git branch --show-current
git remote -v
gh auth status
npm run scan:secrets -- --scan . --redact
git log --all --oneline --decorate -20
```

El escáner debe redactar valores. Si el comando o una herramienta imprime un secreto, detén el
procedimiento, rota la credencial y elimina el log/captura inseguro según la política de incidentes.

## 1. Revocar y rotar credenciales

### 1.1 GitHub PAT

**UI (revocación y creación):**

1. En GitHub, avatar → **Settings** → **Developer settings** → **Personal access tokens**.
2. Revisa **Fine-grained tokens** y **Tokens (classic)**. Revoca cada PAT histórico o no
   identificado con **Revoke**; confirma solo después de verificar que no es necesario para otro
   servicio.
3. Selecciona **Generate new token** (preferir *Fine-grained*), limita propietario, repositorios,
   permisos mínimos y expiración corta. Genera, copia el valor solo al gestor de secretos y no lo
   vuelvas a mostrar.
4. Actualiza el consumidor autorizado (por ejemplo, el secreto `PAT_SYNC` de Actions) desde
   **Repository → Settings → Secrets and variables → Actions**. Usa **Update**, no lo escribas en
   un archivo del checkout.
5. En **Settings → Applications → Authorized OAuth Apps / GitHub Apps**, revoca integraciones
   históricas que ya no tengan owner.

**CLI segura:** la CLI no puede crear un PAT sin exponer el flujo en el navegador; úsala para
comprobar la identidad y retirar la copia local:

```cmd
gh auth status --hostname github.com
gh auth logout --hostname github.com
gh auth status --hostname github.com
```

El `logout` solo elimina la autenticación local; la revocación real se hace en la UI. Reautentica
con `gh auth login --hostname github.com --web` únicamente después de revocar/rotar y sin pasar el
PAT como argumento.

### 1.2 Token de Telegram

**UI de BotFather:**

1. Abre el chat oficial **@BotFather** y confirma que es la cuenta verificada.
2. Ejecuta `/mybots` → selecciona el bot → **API Token** → **Revoke current token** y confirma.
3. En el mismo menú solicita **Generate new token** (o `/token`), copia el nuevo valor directamente
   al gestor de secretos y actualiza el consumidor autorizado.
4. Si el bot ya no tiene owner o no debe existir, usa `/deletebot` solo tras una confirmación
   explícita del propietario; es una eliminación irreversible.

No introduzcas el token en la línea de comandos, en URLs, en `set`, ni en logs. Comprueba el
funcionamiento desde la integración que lo consume, con su secreto inyectado por el gestor de
secretos. Si no puedes identificar el consumidor, revoca y registra la incertidumbre.

### 1.3 Secretos históricos o de proveedor desconocido

1. Identifica únicamente ruta, commit, línea y patrón; no copies el valor.
2. Busca el working tree y el historial con salida redactada:

```cmd
npm run scan:secrets -- --scan . --redact
git log --all --oneline -- .
git grep -n -I -E "PAT|TOKEN|SECRET|API_KEY|BOT[ _-]?TOKEN" -- .
```

3. Para cada hallazgo, revoca en el proveedor correspondiente, rota por un valor nuevo en el
   gestor de secretos, invalida sesiones asociadas y revisa auditoría/uso. Para un proveedor
   desconocido: deshabilita el servicio o identidad afectada y escala como incidente privado.
4. Elimina la referencia del árbol mediante un cambio revisable; no reescribas historia ni uses una
   allowlist para ocultar un secreto real sin aprobación del owner y plan de remediación histórica.
5. Vuelve a ejecutar el escáner local y valida también las alertas de GitHub (sección 4).

## 2. Activar controles en GitHub

Sustituye `OWNER` y `REPO` por nombres, nunca por credenciales. Primero inspecciona; aplica cambios
solo después de confirmar que el repositorio y la rama son correctos.

### UI recomendada

En **Repository → Settings → Code security and analysis**:

1. **Secret Scanning:** **Enable**.
2. **Push protection:** **Enable** y confirma el modo de bloqueo de pushes con secretos.
3. **Dependabot alerts:** **Enable**.
4. **Dependabot security updates:** **Enable**. Revisa `.github/dependabot.yml` y evita activar dos
   bots con responsabilidades duplicadas sin decisión documentada.

En **Settings → Rules → Rulesets → New branch ruleset** (o **Branches → Add branch protection
rule**, según la UI disponible):

1. Crea reglas para `main` y `develop` (dos reglas si tienen políticas distintas).
2. Activa **Restrict deletions**, **Block force pushes**, **Require a pull request before merging**,
   al menos una aprobación independiente y **Dismiss stale approvals**.
3. Activa **Require status checks to pass** y selecciona los checks obligatorios de CI/security.
4. Mantén el bypass del propietario solo para una emergencia documentada; no lo uses para el flujo
   normal. Guarda y prueba con una rama sin privilegios.

### CLI equivalente (GitHub CLI, cambios administrativos)

```cmd
gh auth status --hostname github.com
gh api repos/OWNER/REPO --jq "{default_branch:.default_branch,visibility:.visibility}"
gh api repos/OWNER/REPO --jq ".security_and_analysis"
```

Tras verificar la salida, el owner puede habilitar los controles (estos comandos cambian GitHub):

```cmd
gh api --method PATCH repos/OWNER/REPO -f "security_and_analysis[secret_scanning][status]=enabled" -f "security_and_analysis[secret_scanning_push_protection][status]=enabled"
gh api --method PUT repos/OWNER/REPO/vulnerability-alerts
gh api --method PUT repos/OWNER/REPO/automated-security-fixes
```

Si una opción no está disponible por plan, visibilidad o permisos, conserva la salida del error y
activa el control desde la UI; no lo “soluciones” desactivando una protección existente.

Los rulesets complejos son preferibles desde la UI para evitar errores de JSON. Si se usa API,
exporta/revisa el payload en un archivo temporal no versionado y exige una confirmación separada
antes de crear o modificar reglas.

## 3. Publicar cambios con revisión segura

```cmd
git switch -c docs/security-remediation-runbook
git diff --check
npm run scan:secrets -- --scan . --redact
npm run typecheck
npm run lint
git status --short
git diff -- docs/security/MANUAL-REMEDIATION-RUNBOOK.md docs/security/README.md docs/README.md
git add docs/security/MANUAL-REMEDIATION-RUNBOOK.md docs/security/README.md docs/README.md
git commit -m "docs(security): add manual remediation runbook"
git push -u origin docs/security-remediation-runbook
gh pr create --base develop --fill
```

Antes de mergear: revisar el diff como owner, confirmar que no hay valores sensibles, esperar CI,
obtener la aprobación requerida y usar **Squash and merge**. No hagas push directo a `main` o
`develop`, no uses `--admin` para saltarte checks y no publiques `.runtime/`, `.session/`,
`.telemetry/`, bases locales, claves, logs ni credenciales.

## 4. Validar alertas y controles

**UI:**

1. **Security → Secret scanning → Alerts:** confirma que no quedan alertas abiertas sin owner.
2. Abre cada alerta y verifica estado (**Resolved**, **Revoked** o equivalente), razón y fecha; no
   copies el secreto.
3. **Security → Dependabot alerts:** confirma que los avisos críticos/altos tienen actualización,
   excepción documentada o owner/fecha.
4. Revisa **Actions**: los workflows de seguridad terminan correctamente y los checks aparecen
   como obligatorios en el ruleset.
5. Crea una rama de prueba sin contenido sensible para confirmar que PR, aprobación y checks son
   requisitos; no pruebes insertando un token real.

**CLI (solo lectura):**

```cmd
gh api repos/OWNER/REPO/secret-scanning/alerts --paginate --jq ".[] | {number,state,created_at,resolved_at}"
gh api repos/OWNER/REPO/dependabot/alerts --paginate --jq ".[] | {number,state,severity,created_at}"
gh api repos/OWNER/REPO/rulesets --jq ".[] | {id,name,enabled,enforcement}"
gh run list --repo OWNER/REPO --limit 10
```

Guarda conteos y estados, no payloads. Una alerta nueva, un check fallido o una protección ausente
bloquea la publicación y requiere triage.

## 5. Clasificar y, solo con confirmación, eliminar artefactos históricos

La normativa vigente establece que `.archive/` es histórico no ejecutable y `protected/*.ps1.enc`
es histórico sensible/cifrado: no se descifra, invoca ni incorpora al runtime. `.backups/` contiene
respaldos y no es documentación publicable. El valor predeterminado es conservar/archivar; borrar
requiere demostrar que no existe obligación de auditoría, recuperación, compatibilidad o retención.
Referencias: [`rules/NORMATIVA-SCRIPT-LIFECYCLE.md`](../../rules/NORMATIVA-SCRIPT-LIFECYCLE.md) y
[`docs/operations/PS1-LEGACY-POLICY.md`](../operations/PS1-LEGACY-POLICY.md).

### Inventario y clasificación (no destructivo)

```cmd
dir /a /s .archive
dir /a /s .backups
dir /a /s protected\*.ps1.enc
git ls-files ".archive/*" ".backups/*" "protected/*.ps1.enc"
git grep -n -I -E "\.archive|\.backups|protected/.*\.ps1\.enc|protected\\.*\.ps1\.enc" -- .
```

Clasifica cada entrada como `archived`, `protected`, `backup-retained` o `candidate`; registra
owner, motivo, fecha de revisión, obligación de retención y si existe caller. Antes de eliminar,
confirma: cero callers funcionales, reemplazo probado si aplica, copia de recuperación aprobada,
retención cumplida y revisión del owner. Nunca borres para ocultar un hallazgo.

### Borrado con doble confirmación explícita

El siguiente patrón es intencionalmente manual. Sustituye la ruta **solo por una lista previamente
revisada**, no por una variable proveniente de entrada externa. Si la respuesta no coincide, no borra:

```cmd
set /p CONFIRM=Escribe BORRAR-ARCHIVO para continuar: 
if /I not "%CONFIRM%"=="BORRAR-ARCHIVO" echo Cancelado.& goto :eof
set /p CONFIRM2=Confirma de nuevo la ruta y escribe BORRAR-ARCHIVO: 
if /I not "%CONFIRM2%"=="BORRAR-ARCHIVO" echo Cancelado.& goto :eof
del /f /q "RUTA_PREVIAMENTE_REVISADA"
```

Para un directorio completo, usa `rmdir /s /q` solo con la misma doble confirmación y únicamente
si el owner aprobó explícitamente el borrado del directorio. No uses comodines amplios ni ejecutes
este patrón sobre `protected/` o respaldos sin una decisión formal de retención.

## Checklist de cierre

- [ ] PATs antiguos revocados; nuevo PAT mínimo almacenado fuera del repo; copia local retirada.
- [ ] Token de Telegram revocado/rotado en BotFather; consumidor actualizado sin imprimirlo.
- [ ] Secretos históricos identificados, revocados y tratados; escáner sin nuevos hallazgos.
- [ ] Secret Scanning, Push Protection, Dependabot alerts y security updates activos.
- [ ] Rulesets de `main`/`develop` bloquean push directo, force-push y merge sin PR/checks.
- [ ] Alertas GitHub y workflows revisados; cada excepción tiene owner y fecha.
- [ ] PR de documentación revisado, CI verde y merge aprobado; ningún código funcional modificado.
- [ ] `.archive`, `.backups` y `protected/*.ps1.enc` clasificados; borrado solo con confirmación y
      evidencia de retención.

### Índices relacionados

- [Índice de seguridad](README.md)
- [Índice general de documentación](../README.md)
- [Secret scanning](SECRET-SCANNING.md)
- [Estrategia de publicación](../REPOSITORY-PUBLICATION.md)
- [Flujo de desarrollo y revisión](../guides/DEVELOPMENT-WORKFLOW.md)
