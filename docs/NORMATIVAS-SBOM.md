# NORMATIVAS-SBOM.md — Software Bill of Materials Standards

Version: 1.0.0
Framework: SPDX 2.3 + CycloneDX 1.6 + NTIA Minimum Elements
Last updated: 2026-05-11

---

## 1. PROPOSITO

Define los estandares de generacion, validacion, y mantenimiento de Software Bill of Materials (SBOM) para el stack Foundation.

---

## 2. FORMATOS SOPORTADOS

| Formato | Version | Uso | Herramienta |
|---------|---------|-----|-------------|
| CycloneDX | 1.6 | SBOM principal | Trivy + CycloneDX CLI |
| SPDX | 2.3 | Compliance legal | SPDX Tools |

Formato canonical: CycloneDX 1.6 (generado por Trivy en CI)

---

## 3. CONTROLES OBLIGATORIOS

### 3.1 SBOM Generation

1. **MUST** generar SBOM en cada release
2. **MUST** incluir todas las dependencias directas y transitivas
3. **MUST** generar SBOM en formato CycloneDX 1.6
4. **MUST** incluir metadatos: herramienta, timestamp, formato spec
5. **MUST** incluir informacion de licencias
6. **SHOULD** incluir hashes de componentes (SHA-256)
7. **SHOULD** incluir vulnerabilidades conocidas asociadas

### 3.2 SBOM Validation

| Check | Tool | Gate |
|-------|------|------|
| Formato valido | CycloneDX CLI validator | Release |
| Vulnerabilidades conocidas | Trivy | CI (pull_request) |
| Licencias incompatibles | License Finder | PR a develop |
| Componentes obsoletos | Dependabot alerts | Semanal |
| Dependencias no declaradas | OWASP Dependency Check | CI |

### 3.3 SBOM Distribution

1. **MUST** almacenar SBOM como artifact de release en GitHub
2. **MUST** exponer SBOM via API de seguridad
3. **MUST** mantener historico de SBOMs (todos los releases)
4. **SHOULD** firmar SBOM con GPG

---

## 4. CI/CD INTEGRATION

```yaml
- name: Generate SBOM
  run: trivy fs --format cyclonedx --output sbom-cyclonedx.json .
- name: Validate SBOM
  run: cyclonedx-cli validate --input-file sbom-cyclonedx.json
- name: Upload SBOM
  uses: actions/upload-artifact@v7
  with:
    name: sbom-COMMIT_SHA
    path: sbom-cyclonedx.json
    retention-days: 90
```

---

## 5. COMPLIANCE CHECKPOINTS

1. [ ] SBOM generado en cada release (CycloneDX 1.6)
2. [ ] SBOM validado (formato + schema)
3. [ ] Vulnerabilidades escaneadas (Trivy) antes del release
4. [ ] Licencias auditadas (sin incompatibilidades)
5. [ ] Dependencias actualizadas (Dependabot activo)
6. [ ] SBOM almacenado como artifact de release
7. [ ] SBOM firmado (GPG meta)
8. [ ] Historial de SBOMs mantenido
9. [ ] Dependencias no declaradas detectadas
10. [ ] SBOM accesible via API

---

## 6. REFERENCIAS

| Resource | Path |
|----------|------|
| CycloneDX Spec 1.6 | cyclonedx.org/specification |
| SPDX 2.3 Spec | spdx.dev/specifications |
| NTIA Minimum Elements | ntia.gov/SBOM |
| Security Scan Workflow | .github/workflows/security-scan.yml |
| Dependabot Config | .github/dependabot.yml |
| Security Normatives | docs/NORMATIVAS-SEGURIDAD.md |

---

_Version: 1.0.0 - 2026-05-11 - Status: ACTIVE_
