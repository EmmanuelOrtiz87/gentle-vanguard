# Ciclo de vida de credenciales

## Inventario local

Ejecutar `npm run credentials:inventory -- --json`. Se pueden añadir exclusiones con
`--exclude <segmento>`; por defecto se omiten `.git`, dependencias, runtime, sesiones, telemetría,
backups, artefactos compilados y archivos de credenciales. La salida contiene únicamente metadatos.

## Principios

`credentials:inventory` es estrictamente read-only. Enumera nombres y metadatos operativos, pero no
lee valores para mostrarlos, no calcula hashes y no realiza llamadas remotas. Los secretos viven
fuera del repositorio y las rutas se presentan de forma abstracta.

## Estrategia de almacenamiento

- Usar un secret manager (Vault, AWS Secrets Manager/KMS o Azure Key Vault) como fuente de verdad,
  con RBAC, MFA, auditoría y acceso just-in-time.
- Inyectar referencias mediante el runtime o el gestor de secretos; no guardar valores en código,
  JSON, logs, shell history o artefactos de CI.
- En CI, preferir GitHub Environments/Secrets con permisos mínimos y revisiones de ambientes.

## GitHub App y OIDC

Preferir una GitHub App con permisos mínimos y tokens de instalación de corta duración. Para cloud,
usar OIDC de GitHub Actions con trust policy limitada a repositorio, rama/entorno y workflow; no
usar PAT persistentes para automatización. Los tokens de instalación y credenciales OIDC deben tener
TTL corto y no se deben persistir.

## TTL y rotación

Aplicar TTL mínimo compatible con la operación: tokens de sesión y federados deben expirar
automáticamente; API keys y secretos estáticos deben tener propietario, fecha de revisión y rotación
periódica. La inventaría marca rotación automática solo cuando la configuración evidencia identidad
dinámica, OIDC, role o TTL; el resto requiere rotación manual documentada.

Rotación manual inevitable incluye BotFather (revocar y emitir token de bot), PAT (crear/revocar
desde GitHub) y master key (planificar re-encriptación y custodios). Estas acciones requieren
aprobación del propietario del servicio y registro de quién, por qué y cuándo.

## Procedimiento de doble credencial y revocación

1. Crear la credencial nueva con permisos y expiración correctos, sin retirar la anterior.
2. Registrar la nueva en el secret manager y desplegarla como credencial primaria; mantener la
   anterior como fallback temporal.
3. Probar autenticación y operaciones mínimas sin imprimir valores.
4. Confirmar métricas, logs y consumidores migrados; no prolongar el periodo de solapamiento más
   allá del TTL acordado.
5. Revocar la credencial antigua en el proveedor y eliminar su referencia operativa.
6. Verificar que la antigua falla, que la nueva sigue funcionando y conservar únicamente evidencia
   de metadatos/auditoría.

Ante exposición sospechada, revocar primero, preservar evidencia sin copiar el valor, emitir
reemplazo y revisar logs de acceso. Nunca incluir secretos o hashes reversibles en incidencias.
