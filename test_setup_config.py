import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


MODULE_PATH = Path(__file__).with_name("setup-config.py")
SPEC = importlib.util.spec_from_file_location("setup_config", MODULE_PATH)
setup_config = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(setup_config)


class SetupConfigTests(unittest.TestCase):
    def test_setup_writes_vscode_and_zededitor_configuration(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "config.json"
            vscode_mcp = Path(temp_dir) / "vscode_mcp.py"
            vscode_mcp.write_text("#!/usr/bin/env python3\n", encoding="utf-8")
            zed_mcp = Path(temp_dir) / "zed_mcp.py"
            zed_mcp.write_text("#!/usr/bin/env python3\n", encoding="utf-8")

            with patch.object(setup_config, "CONFIG_PATH", config_path), \
                 patch.object(setup_config, "VSCODE_MCP", vscode_mcp), \
                 patch.object(setup_config, "ZED_MCP", zed_mcp):
                result = setup_config.main()

            self.assertEqual(result, 0)
            config = json.loads(config_path.read_text(encoding="utf-8"))

        self.assertIn("vscode", config["mcpServers"])
        self.assertIn("zededitor", config["mcpServers"])
        self.assertEqual(
            config["mcpServers"]["vscode"]["args"],
            [str(vscode_mcp)],
        )
        self.assertEqual(
            config["mcpServers"]["zededitor"]["args"],
            [str(zed_mcp)],
        )

    def test_setup_removes_legacy_servers(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "config.json"
            initial_config = {
                "mcpServers": {
                    "roblox": {"command": "old_roblox"},
                    "effectcraft": {"command": "old_ec"},
                    "zed": {"command": "old_zed"}
                }
            }
            config_path.write_text(json.dumps(initial_config), encoding="utf-8")

            vscode_mcp = Path(temp_dir) / "vscode_mcp.py"
            vscode_mcp.write_text("#!/usr/bin/env python3\n", encoding="utf-8")
            zed_mcp = Path(temp_dir) / "zed_mcp.py"
            zed_mcp.write_text("#!/usr/bin/env python3\n", encoding="utf-8")

            with patch.object(setup_config, "CONFIG_PATH", config_path), \
                 patch.object(setup_config, "VSCODE_MCP", vscode_mcp), \
                 patch.object(setup_config, "ZED_MCP", zed_mcp):
                result = setup_config.main()

            self.assertEqual(result, 0)
            config = json.loads(config_path.read_text(encoding="utf-8"))

        self.assertNotIn("roblox", config["mcpServers"])
        self.assertNotIn("effectcraft", config["mcpServers"])
        self.assertNotIn("zed", config["mcpServers"])
        self.assertIn("vscode", config["mcpServers"])
        self.assertIn("zededitor", config["mcpServers"])


if __name__ == "__main__":
    unittest.main()
