import json
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import zed_mcp


class ZedMcpTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name).resolve()
        self.workspace = self.root / "workspace"
        self.workspace.mkdir()
        self.root_patch = patch.object(zed_mcp, "get_root", return_value=self.workspace)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.addCleanup(self.temp.cleanup)

    def test_catalog_has_28_unique_tools(self):
        names = [tool["name"] for tool in zed_mcp.TOOLS]
        self.assertEqual(len(names), 28)
        self.assertEqual(len(set(names)), 28)
        for name in ("delete_file", "apply_patch", "git_add", "git_commit", "run_command"):
            self.assertIn(name, names)

    def test_file_operations_stay_in_workspace(self):
        zed_mcp.create_file("src/app.py", "def hello():\n    return 'world'\n")
        self.assertIn("hello", zed_mcp.read_file("src/app.py"))
        outline = zed_mcp.get_file_outline("src/app.py")
        self.assertEqual(outline, [{"name": "hello", "line": 1}])
        zed_mcp.edit_file("src/app.py", "world", "zed")
        self.assertIn("zed", zed_mcp.read_file("src/app.py"))
        self.assertEqual(zed_mcp.find_files(".", "*.py"), ["src/app.py"])

        with self.assertRaises(ValueError):
            zed_mcp.read_file("../outside.txt")

    def test_apply_patch(self):
        zed_mcp.create_file("test.txt", "line1\nline2\nline3\n")
        zed_mcp.apply_patch(
            "test.txt",
            [{"old_text": "line2", "new_text": "line_two"}]
        )
        self.assertEqual(zed_mcp.read_file("test.txt"), "line1\nline_two\nline3\n")

    def test_delete_file_safety(self):
        zed_mcp.create_file("file.txt", "content")
        (self.workspace / "dir").mkdir()
        self.assertIn("Deleted", zed_mcp.delete_file("file.txt"))
        with self.assertRaises(IsADirectoryError):
            zed_mcp.delete_file("dir")
        with self.assertRaises(ValueError):
            zed_mcp.delete_file(".")

    def test_handle_request_initialize_and_tools(self):
        out = io.StringIO()
        with patch("sys.stdout", out):
            zed_mcp.handle_request({
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "rootUri": self.workspace.as_uri(),
                }
            })
            resp = json.loads(out.getvalue().strip())
            self.assertEqual(resp["id"], 1)
            self.assertEqual(resp["result"]["serverInfo"]["name"], "zed-workspace-mcp")

        out = io.StringIO()
        with patch("sys.stdout", out):
            zed_mcp.handle_request({
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/list",
                "params": {}
            })
            resp = json.loads(out.getvalue().strip())
            self.assertEqual(len(resp["result"]["tools"]), 28)

    def test_handle_request_tool_call_error_format(self):
        out = io.StringIO()
        with patch("sys.stdout", out):
            zed_mcp.handle_request({
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": {
                    "name": "read_file",
                    "arguments": {"path": "non_existent.txt"}
                }
            })
            resp = json.loads(out.getvalue().strip())
            self.assertTrue(resp["result"].get("isError"))
            self.assertIn("Error", resp["result"]["content"][0]["text"])


class WorkspaceResolutionTests(unittest.TestCase):
    def test_env_var_override(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmppath = Path(tmpdir).resolve()
            with patch.dict("os.environ", {"ZED_WORKSPACE": str(tmppath)}):
                zed_mcp.WORKSPACE_OVERRIDE = None
                self.assertEqual(zed_mcp.get_root(), tmppath)


if __name__ == "__main__":
    unittest.main()
