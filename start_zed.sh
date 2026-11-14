#!/usr/bin/env bash
# ==============================================================================
# Snapgent Bridge for Zed Editor (Linux)
# Connects DeepSeek, Qwen, Claude, ChatGPT web chat to Zed Editor via MCP
# ==============================================================================
set -euo pipefail

cd "$(dirname "$0")" || exit 1

BRIDGE_PORT="${ZS_BRIDGE_PORT:-17613}"
mkdir -p logs 2>/dev/null || true
LOG_FILE="logs/start_zed.log"

# ANSI Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$LOG_FILE" 2>/dev/null || true
}

echo -e "${CYAN}${BOLD}"
echo "  ========================================================"
echo "    ⚡ Snapgent Connector for Zed Editor (Linux & macOS)"
echo "    Support: DeepSeek, Qwen, Claude, ChatGPT -> Zed Editor"
echo "  ========================================================"
echo -e "${NC}"

log "===== start_zed.sh launched ====="

# Check bridge.py and zed_mcp.py exist
if [ ! -f "./bridge.py" ] || [ ! -f "./zed_mcp.py" ]; then
    echo -e "${RED}  ERROR: bridge.py or zed_mcp.py is missing.${NC}"
    log "FATAL: required script not found."
    exit 1
fi

chmod +x ./zed_mcp.py 2>/dev/null || true

# 1. Check Python
echo -e "  ${YELLOW}[1/4] Checking Python 3.9+...${NC}"
PY=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1 &&
        "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' >/dev/null 2>&1; then
        PY="$candidate"
        break
    fi
done

if [ -z "$PY" ]; then
    echo -e "${RED}  ERROR: Python 3.9+ was not found. Please install Python 3.${NC}"
    log "FATAL: no Python 3.9+ found."
    exit 1
fi
echo -e "        ${GREEN}✓ Found: $("$PY" --version 2>&1)${NC}"

# 2. Check websockets
echo -e "  ${YELLOW}[2/4] Checking websockets dependency...${NC}"
if ! "$PY" -c "import websockets" >/dev/null 2>&1; then
    echo "        Installing websockets dependency..."
    if ! "$PY" -m pip install --user websockets >/dev/null 2>&1 ||
        ! "$PY" -c "import websockets" >/dev/null 2>&1; then
        VENV_DIR=".venv-snapgent"
        if [ ! -x "$VENV_DIR/bin/python" ]; then
            "$PY" -m venv "$VENV_DIR" || {
                echo -e "${RED}  ERROR: Could not install websockets or create local venv.${NC}"
                exit 1
            }
        fi
        PY="$VENV_DIR/bin/python"
        "$PY" -m pip install websockets || {
            echo -e "${RED}  ERROR: Failed to install websockets in venv.${NC}"
            exit 1
        }
    fi
fi
echo -e "        ${GREEN}✓ websockets library ready${NC}"

# 3. Configure MCP servers
echo -e "  ${YELLOW}[3/4] Configuring MCP servers (Zed + VS Code)...${NC}"
"$PY" "./setup-config.py" >/dev/null 2>&1 || true
echo -e "        ${GREEN}✓ zed_mcp.py configured (28 workspace tools)${NC}"

# 4. Check existing bridge process on ports 17613 and 17614
HTTP_PORT="${ZS_HTTP_PORT:-17614}"
echo -e "  ${YELLOW}[4/4] Checking ports ${BRIDGE_PORT} and ${HTTP_PORT}...${NC}"
if command -v lsof >/dev/null 2>&1; then
    for port in "$BRIDGE_PORT" "$HTTP_PORT"; do
        OLD_PIDS="$(lsof -ti "tcp:$port" -s TCP:LISTEN 2>/dev/null || true)"
        for old_pid in $OLD_PIDS; do
            OLD_COMMAND="$(ps -p "$old_pid" -o args= 2>/dev/null || true)"
            if [[ "$OLD_COMMAND" == *bridge.py* ]]; then
                echo -e "        ${YELLOW}Stopping previous bridge process (PID $old_pid)...${NC}"
                kill -TERM "$old_pid" 2>/dev/null || true
                sleep 1
            fi
        done
    done
fi
echo -e "        ${GREEN}✓ Ports ${BRIDGE_PORT} (WebSocket) and ${HTTP_PORT} (OpenAI HTTP) are ready${NC}"

echo
echo -e "${GREEN}${BOLD}  🚀 Bridge & OpenAI Proxy Siap Dijalankan!${NC}"
echo -e "  --------------------------------------------------------"
echo -e "  ${BOLD}Cara Pakai (Chat Langsung di Dalam Zed Editor):${NC}"
echo -e "  1. Buka tab chat di browser (biarkan terbuka di background):"
echo -e "     • DeepSeek : ${CYAN}https://chat.deepseek.com${NC} atau"
echo -e "     • Qwen     : ${CYAN}https://chat.qwen.ai${NC}"
echo -e "  2. Buka project Anda di Zed Editor."
echo -e "  3. Buka panel Agent Zed (${BOLD}Ctrl + ?${NC})."
echo -e "  4. Pilih model: ${BOLD}${GREEN}DeepSeek Web (Snapgent Free)${NC} atau ${BOLD}${GREEN}Qwen Web (Snapgent Free)${NC}"
echo -e "  5. Chat langsung di Zed! Prompt akan diteruskan ke browser di latar belakang,"
echo -e "     dan jawabannya di-stream balik ke Zed Editor secara real-time!"
echo -e "  --------------------------------------------------------"
echo -e "  ${YELLOW}Tekan Ctrl+C untuk menghentikan bridge.${NC}"
echo

log "Starting bridge.py with $PY"
exec "$PY" bridge.py
