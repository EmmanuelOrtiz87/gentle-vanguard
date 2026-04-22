# Script Normalization Audit Report

**Date**: 2026-04-22 10:32:08
**Total Scripts**: 120
**Scripts with Issues**: 21
**Scripts Fixed**: 0

## Normalization Standards

Scripts must comply with:
- No emojis or special Unicode characters
- UTF-8 encoding without BOM
- Balanced braces, parentheses, and here-strings
- Valid PowerShell syntax
- ASCII-only text (except in comments for documentation)

## Issues Found

### .\scripts\diagnostics\validate-script-governance.ps1
Issues:
- Syntax error: Token 'Script' inesperado en la expresión o la instrucción.

### .\scripts\foundation\bootstrap-workspace.ps1
Issues:
- Unbalanced braces: 219 open, 217 closed

### .\scripts\foundation\wf.ps1
Issues:
- Unbalanced parentheses: 88 open, 99 closed

### .\scripts\project\migrate.ps1
Issues:
- Unbalanced parentheses: 37 open, 36 closed
- Syntax error: La referencia de variable no es válida. El carácter ':' no va seguido de un carácter de nombre de variable válido. Considere la posibilidad de usar ${} para delimitar el nombre.
- Syntax error: Token '$envVar' inesperado en la expresión o la instrucción.
- Syntax error: Falta el paréntesis de cierre ')' en la lista de parámetros de la función.
- Syntax error: El token '&&' no es un separador de instrucciones válido en esta versión.
- Syntax error: El token '&&' no es un separador de instrucciones válido en esta versión.
- Syntax error: El token '&&' no es un separador de instrucciones válido en esta versión.

### .\scripts\security\encryption-manager.ps1
Issues:
- Unbalanced braces: 15 open, 13 closed
- Syntax error: Token ':' inesperado en la expresión o la instrucción.
- Syntax error: Falta el operador '=' después de la clave en el literal de hash.
- Syntax error: El literal de hash estaba incompleto.
- Syntax error: Falta la llave de cierre "}" en el bloque de instrucciones o la definición de tipo.

### .\scripts\security\input-validator.ps1
Issues:
- Unbalanced parentheses: 36 open, 35 closed

### .\scripts\testing\git-hooks-setup.ps1
Issues:
- Unbalanced braces: 7 open, 4 closed
- Syntax error: Falta la cadena en el terminador: '@.
- Syntax error: Falta la llave de cierre "}" en el bloque de instrucciones o la definición de tipo.

### .\scripts\utilities\create-gitflow-branch.ps1
Issues:
- Unbalanced parentheses: 35 open, 40 closed

### .\scripts\utilities\create-skill.ps1
Issues:
- Syntax error: Token '$_""' inesperado en la expresión o la instrucción.
- Syntax error: Token '""' inesperado en la expresión o la instrucción.
- Syntax error: Token '$SkillName""' inesperado en la expresión o la instrucción.
- Syntax error: Token '""' inesperado en la expresión o la instrucción.
- Syntax error: Falta una expresión después del operador unario '-'.
- Syntax error: Token 'name:' inesperado en la expresión o la instrucción.
- Syntax error: Falta la especificación de archivo después del operador de redirección.
- Syntax error: Token ':' inesperado en la expresión o la instrucción.
- Syntax error: Falta ] al final del atributo o literal de tipo.
- Syntax error: Token 'when' inesperado en la expresión o la instrucción.
- Syntax error: Token '[Rule' inesperado en la expresión o la instrucción.
- Syntax error: Falta ] al final del atributo o literal de tipo.
- Syntax error: Token ']' inesperado en la expresión o la instrucción.
- Syntax error: Token '[Rule' inesperado en la expresión o la instrucción.
- Syntax error: Falta ] al final del atributo o literal de tipo.
- Syntax error: Token ']' inesperado en la expresión o la instrucción.
- Syntax error: Token '[Step' inesperado en la expresión o la instrucción.
- Syntax error: Falta ] al final del atributo o literal de tipo.
- Syntax error: Token ']' inesperado en la expresión o la instrucción.
- Syntax error: Token '[Step' inesperado en la expresión o la instrucción.
- Syntax error: Falta ] al final del atributo o literal de tipo.
- Syntax error: Token ']' inesperado en la expresión o la instrucción.
- Syntax error: Falta ] al final del atributo o literal de tipo.
- Syntax error: Token 'the' inesperado en la expresión o la instrucción.
- Syntax error: Token 'Created' inesperado en la expresión o la instrucción.
- Syntax error: Falta la cadena en el terminador: ".
- Syntax error: Falta la llave de cierre "}" en el bloque de instrucciones o la definición de tipo.
- Syntax error: Falta la llave de cierre "}" en el bloque de instrucciones o la definición de tipo.
- Syntax error: Falta la llave de cierre "}" en el bloque de instrucciones o la definición de tipo.
- Syntax error: El operador -- solamente funciona en variables o en propiedades.
- Syntax error: El operador -- solamente funciona en variables o en propiedades.

### .\scripts\utilities\enable-optional-post-commit.ps1
Issues:
- Unbalanced parentheses: 38 open, 40 closed

### .\scripts\utilities\end-session.ps1
Issues:
- Unbalanced here-strings: 1 open, 3 closed

### .\scripts\utilities\export-backlog-csv.ps1
Issues:
- Syntax error: Falta un argumento en la lista de parámetros.

### .\scripts\utilities\generate-audit-report.ps1
Issues:
- Unbalanced here-strings: 3 open, 2 closed
- Syntax error: Falta la cadena en el terminador: "@.

### .\scripts\utilities\invoke-ai-review.ps1
Issues:
- Unbalanced here-strings: 3 open, 4 closed
- Syntax error: Token '(' inesperado en la expresión o la instrucción.

### .\scripts\utilities\judgment-day.ps1
Issues:
- Unbalanced parentheses: 57 open, 60 closed

### .\scripts\utilities\migrate-structure.ps1
Issues:
- Syntax error: Token '@(' inesperado en la expresión o la instrucción.
- Syntax error: Token '@(' inesperado en la expresión o la instrucción.
- Syntax error: Token ''adopt-existing'' inesperado en la expresión o la instrucción.

### .\scripts\utilities\session-idle-monitor.ps1
Issues:
- Unbalanced parentheses: 36 open, 40 closed

### .\scripts\utilities\session-manager.ps1
Issues:
- Unbalanced parentheses: 78 open, 80 closed

### .\scripts\utilities\simplify-text.ps1
Issues:
- Unbalanced parentheses: 73 open, 74 closed

### .\scripts\utilities\wf.ps1
Issues:
- Unbalanced braces: 501 open, 500 closed
- Unbalanced here-strings: 4 open, 6 closed
- Unbalanced parentheses: 664 open, 666 closed

### .\scripts\validation\homologate-workspace.ps1
Issues:
- Unbalanced parentheses: 119 open, 124 closed

## Compliance Status
**Compliance**: 82.5%

