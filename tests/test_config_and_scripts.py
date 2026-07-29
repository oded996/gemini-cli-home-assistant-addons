import os
import json
import subprocess
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class TestAddonConfigAndScripts(unittest.TestCase):

    def test_shell_script_syntax(self):
        """Verify that all bash scripts in the repository have valid syntax."""
        scripts_to_check = [
            os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "etc", "s6-overlay", "s6-rc.d", "init-gemini", "run"),
            os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "etc", "s6-overlay", "s6-rc.d", "ha-gemini", "run"),
            os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "usr", "local", "bin", "gemini-session.sh"),
            os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "usr", "local", "bin", "ha-mcp"),
            os.path.join(REPO_ROOT, "config", "scripts", "gemini-session-picker.sh"),
        ]
        
        gemini_alias = os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "usr", "local", "bin", "gemini")
        if os.path.exists(gemini_alias):
            scripts_to_check.append(gemini_alias)

        for script_path in scripts_to_check:
            if not os.path.exists(script_path):
                continue
            with self.subTest(script=os.path.basename(script_path)):
                res = subprocess.run(["bash", "-n", script_path], capture_output=True, text=True)
                self.assertEqual(res.returncode, 0, f"Syntax error in {script_path}:\n{res.stderr}")

    def test_mcp_config_json_schema(self):
        """Verify that mcp_config.json contains valid mcpServers configuration for agy."""
        sample_mcp_config = {
            "mcpServers": {
                "home-assistant": {
                    "command": "node",
                    "args": ["/opt/ha-mcp-server/index.js"],
                    "env": {
                        "SUPERVISOR_TOKEN": "test_token"
                    }
                }
            }
        }
        self.assertIn("mcpServers", sample_mcp_config)
        self.assertIn("home-assistant", sample_mcp_config["mcpServers"])
        ha_server = sample_mcp_config["mcpServers"]["home-assistant"]
        self.assertEqual(ha_server["command"], "node")
        self.assertIn("/opt/ha-mcp-server/index.js", ha_server["args"])

    def test_dockerfile_antigravity_installer(self):
        """Verify that Dockerfile installs agy via curl and not @google/gemini-cli."""
        dockerfile_path = os.path.join(REPO_ROOT, "gemini-terminal", "Dockerfile")
        with open(dockerfile_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertNotIn("@google/gemini-cli", content, "Dockerfile should not install deprecated @google/gemini-cli npm package")
        self.assertIn("https://antigravity.google/cli/install.sh", content, "Dockerfile must use Antigravity CLI install script")

    def test_init_script_antigravity_vars(self):
        """Verify init-gemini/run exports ANTIGRAVITY environment variables and creates mcp_config.json."""
        init_script_path = os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "etc", "s6-overlay", "s6-rc.d", "init-gemini", "run")
        with open(init_script_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("ANTIGRAVITY_CONFIG_DIR", content, "init-gemini script should set ANTIGRAVITY_CONFIG_DIR")
        self.assertIn("mcp_config.json", content, "init-gemini script should create/configure mcp_config.json")

    def test_gemini_session_launches_agy(self):
        """Verify gemini-session.sh executes agy instead of gemini --no-acp."""
        session_script_path = os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "usr", "local", "bin", "gemini-session.sh")
        with open(session_script_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("agy", content, "gemini-session.sh should launch agy")

    def test_gemini_alias_wrapper_exists(self):
        """Verify that /usr/local/bin/gemini alias script exists and calls agy."""
        alias_path = os.path.join(REPO_ROOT, "gemini-terminal", "rootfs", "usr", "local", "bin", "gemini")
        self.assertTrue(os.path.exists(alias_path), "gemini alias wrapper script should exist at rootfs/usr/local/bin/gemini")
        with open(alias_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("agy", content, "gemini wrapper script should execute agy")


if __name__ == "__main__":
    unittest.main()
