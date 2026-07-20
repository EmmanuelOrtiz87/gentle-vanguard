# Tooling

## SAST (Static Application Security Testing)

Analyzes source code without executing it.

| Tool      | Type        | Best For                     |
| --------- | ----------- | ---------------------------- |
| Semgrep   | Rules-based | Custom rules, multi-language |
| SonarQube | Platform    | CI/CD integration, tech debt |
| CodeQL    | Query-based | Deep analysis, complex vulns |
| Brakeman  | Ruby-only   | Rails security               |

**Example Semgrep rule:**

```yaml
rules:
  - id: hardcoded-api-key
    patterns:
      - pattern-regex: API_KEY\s*=\s*['"][A-Za-z0-9]{20,}['"]
    message: 'Hardcoded API key detected'
    severity: ERROR
    languages: [python, javascript, go]
```

## DAST (Dynamic Application Security Testing)

Tests running applications from the outside in.

| Tool           | Type       | Best For                         |
| -------------- | ---------- | -------------------------------- |
| OWASP ZAP      | Free       | Automated scanning, CI/CD        |
| Burp Suite Pro | Commercial | Manual testing, advanced attacks |
| Acunetix       | Commercial | Large-scale automated scanning   |

**ZAP automated scan:**

```bash
# Docker-based automated scan
docker run -v $(pwd):/zap/wrk/ -t ghcr.io/zaproxy/zaproxy \
  zap-full-scan.py \
  -t https://staging.example.com \
  -r zap-report.html
```

## SCA / Dependency Scanning

Identifies known vulnerabilities in third-party dependencies.

| Tool                   | Type          | Best For                       |
| ---------------------- | ------------- | ------------------------------ |
| Trivy                  | Open source   | Containers, repos, filesystems |
| Snyk                   | Commercial    | Developer workflow integration |
| Dependabot             | GitHub-native | Automated PRs for fixes        |
| OWASP Dependency-Check | Open source   | Java/.NET projects             |

**Trivy usage:**

```bash
# Scan a filesystem
trivy fs --severity CRITICAL,HIGH ./my-project

# Scan a Docker image
trivy image myapp:latest --format sarif --output trivy-results.sarif
```

## Container Scanning

```bash
# Scan container with Grype
grype myapp:latest --fail-on high

# Scan Kubernetes manifests with Kube-bench
kube-bench run --targets master,node --check 1.0,2.0
```
