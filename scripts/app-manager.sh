#!/bin/bash
#
# Gentle-Vanguard App Manager
# Script unificado para gestionar todas las apps nativas
#
# Uso:
#   ./app-manager.sh <app> <action>
# 
# Apps: academy-web, archify, command-center, content-cms, design-hub, 
#       gv-analytics, prompt-studio, web-dashboard
# Acciones: start, stop, status, restart
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNTIME_DIR="${PROJECT_ROOT}/.runtime"

# Configuración de apps declare -A APPS declare -A APP_NAMES
APPS=(
  ["academy-web"]="academy-web:4173:python -m http.server 4173 --directory apps/academy-web"
  ["archify"]="archify:5179:node --import tsx apps/archify/server/server.ts"
  ["command-center"]="command-center:8090:node --import tsx apps/command-center/server.ts"
  ["content-cms"]="content-cms:5175:vite --port 5175 --host 127.0.0.1"
  ["design-hub"]="design-hub:8095:python -m http.server 8095 --directory apps/design-hub"
  ["gv-analytics"]="gv-analytics:5174:vite --port 5174 --host 127.0.0.1"
  ["prompt-studio"]="prompt-studio:5172:vite --port 5172 --host 127.0.0.1"
  ["web-dashboard"]="web-dashboard:5173:vite --port 5173 --host 127.0.0.1"
)

# Nombres amigables
declare -A APP_NAMES
APP_NAMES=(
  ["academy-web"]="Academy"
  ["archify"]="Archify"
  ["command-center"]="Command Center"
  ["content-cms"]="Content CMS"
  ["design-hub"]="Design Hub"
  ["gv-analytics"]="Analytics"
  ["prompt-studio"]="Prompt Studio"
  ["web-dashboard"]="Dashboard"
)

show_usage() {
  echo "Gentle-Vanguard App Manager"
  echo ""
  echo "Uso: $0 <app> <action>"
  echo ""
  echo "Apps disponibles:"
  for app in "${!APPS[@]}"; do
    local port=$(echo "${APPS[$app]}" | cut -d: -f2)
    echo "  - ${app} (port ${port})"
  done
  echo ""
  echo "Acciones:"
  echo "  start   - Iniciar app"
  echo "  stop    - Detener app"
  echo "  status  - Verificar estado"
  echo "  restart - Reiniciar app"
  echo ""
  echo "Ejemplos:"
  echo "  $0 design-hub start"
  echo "  $0 command-center restart"
  echo "  $0 design-hub status"
}

get_pidfile() {
  local app=$1
  echo "${RUNTIME_DIR}/app-${app}.pid"
}

is_port_open() {
  local port=$1
  timeout 2 bash -c "cat < /dev/tcp/127.0.0.1/${port}" 2>/dev/null
}

is_process_alive() {
  local pid=$1
  kill -0 "${pid}" 2>/dev/null
}

start_app() {
  local app=$1
  local config="${APPS[$app]}"
  
  if [ -z "${config}" ]; then
    echo "❌ App desconocida: ${app}"
    exit 1
  fi
  
  local app_name=$(echo "${config}" | cut -d: -f1)
  local port=$(echo "${config}" | cut -d: -f2)
  local cmd=$(echo "${config}" | cut -d: -f3-)
  local display_name="${APP_NAMES[$app]}"
  local pidfile=$(get_pidfile "${app}")
  
  echo "🚀 Iniciando ${display_name}..."
  echo "   App: ${app}"
  echo "   Port: ${port}"
  echo "   Command: ${cmd}"
  
  # Verificar si ya está corriendo
  if [ -f "${pidfile}" ]; then
    local old_pid=$(cat "${pidfile}" 2>/dev/null)
    if [ -n "${old_pid}" ] && is_process_alive "${old_pid}"; then
      if is_port_open "${port}"; then
        echo "⚠️  ${display_name} ya está corriendo (PID: ${old_pid}, Port: ${port})"
        return 0
      fi
    fi
    rm -f "${pidfile}"
  fi
  
  # Crear directorio runtime
  mkdir -p "${RUNTIME_DIR}"
  
  # Iniciar proceso
  cd "${PROJECT_ROOT}"
  
  if [[ "${cmd}" == *"python"* ]]; then
    # Python server eval "${cmd} &"
    local pid=$!
  elif [[ "${cmd}" == *"vite"* ]]; then
    # Vite server eval "npx ${cmd} &"
    local pid=$!
  else
    # Node server eval "${cmd} &"
    local pid=$!
  fi
  
  # Guardar PID
  echo "${pid}" > "${pidfile}"
  
  # Esperar a que arranque
  echo "⏳ Esperando a que ${display_name} esté listo..."
  for i in {1..15}; do
    if is_port_open "${port}"; then
      echo "✅ ${display_name} iniciado exitosamente"
      echo "   PID: ${pid}"
      echo "   URL: http://127.0.0.1:${port}"
      return 0
    fi
    sleep 1
  done
  
  echo "❌ Error: ${display_name} no respondió en el puerto ${port}"
  kill "${pid}" 2>/dev/null || true
  rm -f "${pidfile}"
  return 1
}

stop_app() {
  local app=$1
  local config="${APPS[$app]}"
  local display_name="${APP_NAMES[$app]}"
  local port=$(echo "${config}" | cut -d: -f2)
  local pidfile=$(get_pidfile "${app}")
  
  echo "🛑 Deteniendo ${display_name}..."
  
  # Intentar detener por PID
  if [ -f "${pidfile}" ]; then
    local pid=$(cat "${pidfile}" 2>/dev/null)
    if [ -n "${pid}" ] && is_process_alive "${pid}"; then
      echo "   Deteniendo PID ${pid}..."
      kill "${pid}" 2>/dev/null || true
      sleep 2
      
      # Forzar si no cerró
      if is_process_alive "${pid}"; then
        kill -9 "${pid}" 2>/dev/null || true
      fi
    fi
    rm -f "${pidfile}"
  fi
  
  # Fallback: matar por puerto
  local port_pid=$(lsof -t -i:${port} 2>/dev/null || true)
  if [ -n "${port_pid}" ]; then
    echo "   Matando proceso en puerto ${port}..."
    kill "${port_pid}" 2>/dev/null || true
  fi
  
  echo "✅ ${display_name} detenido"
}

status_app() {
  local app=$1
  local config="${APPS[$app]}"
  local display_name="${APP_NAMES[$app]}"
  local port=$(echo "${config}" | cut -d: -f2)
  local pidfile=$(get_pidfile "${app}")
  
  local status="stopped"
  local pid=""
  local pid_alive="false"
  
  if [ -f "${pidfile}" ]; then
    pid=$(cat "${pidfile}" 2>/dev/null)
    if [ -n "${pid}" ] && is_process_alive "${pid}"; then
      pid_alive="true"
    fi
  fi
  
  local port_open="false"
  if is_port_open "${port}"; then
    port_open="true"
  fi
  
  if [ "${port_open}" == "true" ] && [ "${pid_alive}" == "true" ]; then
    status="running"
  elif [ "${port_open}" == "true" ]; then
    status="running (orphan)"
  elif [ "${pid_alive}" == "true" ]; then
    status="starting"
  fi
  
  echo "📊 ${display_name} Status"
  echo "   Estado: ${status}"
  echo "   PID: ${pid:-N/A}"
  echo "   Puerto: ${port} (${port_open == "true" ? "abierto" : "cerrado"})"
  echo "   URL: http://127.0.0.1:${port}"
}

# Main
APP="${1:-}"
ACTION="${2:-}"

if [ -z "${APP}" ] || [ -z "${ACTION}" ]; then
  show_usage
  exit 1
fi

case "${ACTION}" in
  start)
    start_app "${APP}"
    ;;
  stop)
    stop_app "${APP}"
    ;;
  status)
    status_app "${APP}"
    ;;
  restart)
    stop_app "${APP}"
    sleep 1
    start_app "${APP}"
    ;;
  *)
    echo "❌ Acción desconocida: ${ACTION}"
    show_usage
    exit 1
    ;;
esac
