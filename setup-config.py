#!/usr/bin/env python3
"""Discover supported MCP editors (VS Code & Zed) and write local Agent Browser config."""

import json
import sys
from pathlib import Path
from typing import Dict, List, Optional


ROOT = Path(__file__).resolve().parent
CONFIG_PATH = ROOT / "config.json"
VSCODE_MCP = ROOT / "vscode_mcp.py"
ZED_MCP = ROOT / "zed_mcp.py"


def _set_server(
    servers: Dict[str, object],
    server_id: str,
    command: str,
    args: Optional[List[str]] = None,
) -> None:
    current = servers.get(server_id)
    if not isinstance(current, dict):
        current = {}
        servers[server_id] = current
    current["command"] = command
    current["args"] = args or []
    current.setdefault("env", {})


def main() -> int:
    try:
        configuration = {}
        if CONFIG_PATH.is_file():
            try:
                configuration = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                configuration = {}
        if not isinstance(configuration, dict):
            configuration = {}
        servers = configuration.setdefault("mcpServers", {})
        if not isinstance(servers, dict):
            servers = {}
            configuration["mcpServers"] = servers

        # Remove any legacy or duplicate editor entries
        servers.pop("roblox", None)
        servers.pop("effectcraft", None)
        servers.pop("zed", None)

        if VSCODE_MCP.is_file():
            _set_server(servers, "vscode", sys.executable, [str(VSCODE_MCP)])
            print(f"VS Code MCP configured: {VSCODE_MCP}")

        if ZED_MCP.is_file():
            _set_server(servers, "zededitor", sys.executable, [str(ZED_MCP)])
            print(f"Zed MCP configured: {ZED_MCP}")

        CONFIG_PATH.write_text(
            json.dumps(configuration, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        return 0
    except (OSError, RuntimeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
