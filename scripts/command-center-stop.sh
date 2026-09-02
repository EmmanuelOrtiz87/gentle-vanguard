#!/bin/bash
#
# Command Center - Stop Script
# Detiene el servidor Command Center
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RUNTIME_DIR="${PROJECT_ROOT}/.runtime"
PIDFILE="${RUNTIME_DIR}/command-center.pid"

echo "🛑 Deteniendo Command Center..."

if [ -f "${PIDFILE}" ]; then
    PID=$(cat "${PIDFILE}" 2>/dev/null)
    if [ -n "${PID}" ]; then
        echo "   PID encontrado: ${PID}"
        
        # Intentar kill graceful
        if kill "${PID}" 2>/dev/null; then
            echo "   Señal SIGTERM enviada"
            
            # Esperar a que se cierre
            for i in {1..5}; do
                if ! kill -0 "${PID}" 2>/dev/null; then
                    break
                fi
                sleep 1
            done
            
            # Forzar si no cerró
            if kill -0 "${PID}" 2>/dev/null; then
                echo "   Forzando cierre..."
                kill -9 "${PID}" 2>/dev/null || true
            fi
            
            echo "✅ Command Center detenido"
        else
            echo "   Proceso ya no existe"
        fi
    fi
    
    # Limpiar pidfile
    rm -f "${PIDFILE}"
    echo "   PID file limpiado"
else
    echo "⚠️  Command Center no estaba corriendo"
    
    # Fallback: buscar proceso por puerto
    PORT_PID=$(lsof -t -i:8090 2>/dev/null || true)
    if [ -n "${PORT_PID}" ]; then
        echo "   Encontrado proceso en puerto 8090 (PID: ${PORT_PID})"
        kill "${PORT_PID}" 2>/dev/null || true
        echo "✅ Proceso detenido"
    fi
fi
