#!/bin/bash
#
# Command Center - Start Script
# Inicia el servidor Command Center en puerto 8090
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RUNTIME_DIR="${PROJECT_ROOT}/.runtime"
PIDFILE="${RUNTIME_DIR}/command-center.pid"
PORT=8090

echo "🎛️  Starting Command Center..."
echo "   Port: ${PORT}"
echo "   URL: http://127.0.0.1:${PORT}"

# Crear directorio runtime si no existe
mkdir -p "${RUNTIME_DIR}"

# Verificar si ya está corriendo
if [ -f "${PIDFILE}" ]; then
    OLD_PID=$(cat "${PIDFILE}" 2>/dev/null)
    if [ -n "${OLD_PID}" ] && kill -0 "${OLD_PID}" 2>/dev/null; then
        echo "⚠️  Command Center ya está corriendo (PID: ${OLD_PID})"
        echo "   Usa: ./stop.sh"
        exit 1
    else
        rm -f "${PIDFILE}"
    fi
fi

# Iniciar servidor
cd "${PROJECT_ROOT}/apps/command-center"

node --import tsx server.ts &
PID=$!

# Guardar PID
echo "${PID}" > "${PIDFILE}"

# Esperar health check
echo "⏳ Esperando a que Command Center esté listo..."
sleep 2

# Verificar puerto
for i in {1..10}; do
    if curl -s http://127.0.0.1:${PORT}/api/health >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if curl -s http://127.0.0.1:${PORT}/api/health >/dev/null 2>&1; then
    echo "✅ Command Center iniciado exitosamente"
    echo "   PID: ${PID}"
    echo "   URL: http://127.0.0.1:${PORT}"
else
    echo "❌ Error: Command Center no respondió"
    kill "${PID}" 2>/dev/null || true
    rm -f "${PIDFILE}"
    exit 1
fi

cd "${SCRIPT_DIR}"
