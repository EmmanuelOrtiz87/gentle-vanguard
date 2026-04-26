# 📋 Prerequisites - Foundation

**Fecha**: 2026-04-26  
**Descripción**: Lista completa de herramientas requeridas y opcionales para Foundation

---

## 🚀 Instalación Automática

```powershell
# Opción 1: Instalar todo automáticamente
.\scripts\utilities\install-prerequisites.ps1

# Opción 2: Solo verificar estado
.\scripts\utilities\install-prerequisites.ps1 -CheckOnly
```

---

## 🔴 Requeridas (Obligatorias)

| Herramienta | Versión Mínima | Propósito | Instalación |
|------------|----------------|-----------|-------------|
| **Node.js** | 18+ | Runtime JavaScript | [nodejs.org](https://nodejs.org) |
| **npm** | 9+ | Package manager | Incluido con Node.js |
| **Git** | 2.30+ | Control de versiones | [git-scm.com](https://git-scm.com) |

---

## 🟡 Recomendadas (Instalación Automática)

```powershell
# Estas se instalan con el comando anterior
npm install -g lefthook
npm install -g prettier
npm install -g @commitlint/cli @commitlint/config-conventional
```

| Herramienta | Propósito | Instalación |
|------------|-----------|-------------|
| **lefthook** | Git hooks management | `npm install -g lefthook` |
| **prettier** | Code formatting | `npm install -g prettier` |
| **commitlint** | Commit validation | `npm install -g @commitlint/cli` |

---

## 🟢 Opcionales

### Security

| Herramienta | Propósito | Instalación Windows | Instalación Linux/macOS |
|------------|-----------|--------------------|----------------------|
| **trufflehog** | Secrets detection | `choco install trufflehog` | `go install github.com/trufflesecurity/trufflehog/cmd/trufflehog@latest` |

### Python (para scripts Python)

```powershell
# Instalar Python
choco install python

# Instalar pip
pip install safety bandit
```

| Herramienta | Propósito |
|-------------|-----------|
| **safety** | Dependency vulnerability scanning |
| **bandit** | Python security analysis |

---

## 📋 Checklist de Instalación

### 1. Requeridas
- [ ] Node.js (18+)
- [ ] npm (9+)
- [ ] Git (2.30+)

### 2. Recomendadas
- [ ] lefthook
- [ ] prettier
- [ ] commitlint

### 3. Opcionales
- [ ] trufflehog
- [ ] Python (para scripts Python)
- [ ] PowerShell Core (pwsh)

---

## 🔧 Verificación

```powershell
# Verificar todas las herramientas
.\scripts\utilities\install-prerequisites.ps1 -CheckOnly

# Verificar individualmente
node --version
npm --version
git --version
lefthook --version
prettier --version
trufflehog --version
```

---

## ⚠️ Notas Importantes

1. **trufflehog** no está disponible como npm - se instala vía Chocolatey o Go
2. Algunas herramientas requieren permisos de administrador
3. En Windows, ejecutar PowerShell como administrador si hay problemas

---

## 📞 Troubleshooting

### Error: "command not found"
Agregar al PATH:
```powershell
# Para npm global
$env:PATH += ";$env:APPDATA\npm"
```

### Error: "choco not found"
Instalar Chocolatey:
```powershell
# Ejecutar como administrador
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

---

*Documento actualizado: 2026-04-26*