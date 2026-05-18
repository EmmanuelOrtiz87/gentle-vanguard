# Code Style

Convenciones de código para Gentle-Vanguard.

## PowerShell
- Usar cmdlets completos (`Get-ChildItem`, `Set-Content`, `Remove-Item`), NO alias (`ls`, `sc`, `rm`)
- Usar comillas dobles para strings interpolados, simples para verbatim
- `$ErrorActionPreference = 'Stop'` en scripts, `'Continue'` en utilitarios
- Usar pipeline chain operators (`&&`, `||`)
- Funciones: `Get-*`, `Set-*`, `Invoke-*`, `Test-*` — convención Verb-Noun

## TypeScript (MCP Bridge)
- camelCase para variables (`gentleVanguardRoot` — NO hyphens)
- ES2022 target, commonjs modules
- Strict mode siempre active
- Usar `import` en lugar de `require`

## Markdown
- Sin emojis excepto cuando el usuario los usa
- GitHub-flavored markdown (CommonSpec)
- Monospace font rendering
- Código en bloques ``` con lenguaje especificado

## JSON
- 2-space indentation
- Sin trailing commas
- snake_case para keys en configs

## General
- NO agregar comentarios a menos que se solicite
- NO agregar explanation/summary postamble al finalizar ediciones
- Mimic existing code style en archivos adyacentes
- Seguridad: NO exponer secrets/keys en logs, commits, o output
