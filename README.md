<div align="center">

<a href="https://github.com/robyajo/agent-browser">
<img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=800&size=48&duration=3000&pause=1000&color=FACC15&center=true&vCenter=true&width=750&height=90&lines=Agent+Browser;+Snapgent+Connector;+Free+Web+AI+for+VS+Code+%26+Zed" alt="Agent Browser: Snapgent Connector for VS Code & Zed Editor" />
</a>

<p><b>Turn any AI chatbot browser (DeepSeek, Qwen, Claude, ChatGPT) into a powerful coding agent for VS Code & Zed Editor via MCP</b></p>

[![License](https://img.shields.io/badge/LICENSE-GPL--3.0-FACC15?style=flat-square&labelColor=111111&logo=opensourceinitiative&logoColor=FACC15)](LICENSE)
[![Manifest](https://img.shields.io/badge/MANIFEST-V3-FACC15?style=flat-square&labelColor=111111&logo=googlechrome&logoColor=FACC15)](https://developer.chrome.com/docs/extensions/develop/migrate/what-is-mv3/)
[![MCP](https://img.shields.io/badge/PROTOCOL-MCP-FACC15?style=flat-square&labelColor=111111&logo=modelcontextprotocol&logoColor=FACC15)](https://modelcontextprotocol.io/)
[![GitHub Repo](https://img.shields.io/badge/GITHUB-robyajo%2Fagent--browser-blue?style=flat-square&logo=github)](https://github.com/robyajo/agent-browser)

</div>

```console

  █████╗  ██████╗ ███████╗███╗   ██╗████████╗    ██████╗ ██████╗  ██████╗ ██╗    ██╗███████╗███████╗██████╗ 
 ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝    ██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔════╝██╔══██╗
 ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║       ██████╔╝██████╔╝██║   ██║██║ █╗ ██║███████╗█████╗  ██████╔╝
 ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║       ██╔══██╗██╔══██╗██║   ██║██║███╗██║╚════██║██╔══╝  ██╔══██╗
 ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║       ██████╔╝██║  ██║╚██████╔╝╚███╔███╔╝███████║███████╗██║  ██║
 ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝       ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝╚══════╝╚═╝  ╚═╝

  > Browser Extension + Local Bridge for VS Code & Zed Editor (MCP + OpenAI Reverse Proxy)
  > No API key · No subscription · 100% Free Web Models (DeepSeek & Qwen)
```

**Agent Browser (Snapgent Connector)** connects your favorite browser-based AI chats (DeepSeek, Qwen, ChatGPT, Claude, Gemini, etc.) directly to your code editors: **VS Code** and **Zed Editor**.

Describe what you want in plain language — the agent reads, creates, and edits files, searches directory structures, and inspects errors directly inside your active workspace.

---

## ⚡ Key Highlights

- 🆓 **100% Free — No API Key Required**: Leverages web sessions from DeepSeek (`chat.deepseek.com`), Qwen (`chat.qwen.ai`), Claude, ChatGPT, etc.
- 🎯 **Dual Editor Support**:
  - **VS Code**: Native workspace auto-detection with `vscode/*` tools (e.g. `vscode/read_file`, `vscode/write_file`).
  - **Zed Editor**: Native Assistant integration with `zededitor/*` tools (e.g. `zededitor/read_file`, `zededitor/write_file`).
- 🔄 **OpenAI-Compatible Reverse Proxy (Port 17614)**: Allows Zed Editor's Assistant panel to directly chat and execute tools using DeepSeek Web and Qwen Web!
- 🖥️ **Full Multiplatform Support**: Ready-to-run launchers for **Linux**, **macOS**, and **Windows**.
- 🛠️ **28 Rich Workspace Tools per Editor**: File reading, batch edits, patch application, regex search, directory listings, command execution, and workspace info.

---

## 🚀 Quick Start

### 1. Load the Browser Extension

1. Clone or download this repository:
   ```bash
   git clone https://github.com/robyajo/agent-browser.git
   cd agent-browser
   ```
2. Open your browser extension management page:
   - **Chrome / Brave**: `chrome://extensions`
   - **Edge**: `edge://extensions`
3. Enable **Developer mode** (toggle in the top-right corner).
4. Click **Load unpacked** and select the `snapgent-extension` folder.
5. The **Agent Browser** icon will appear in your browser toolbar.

---

### 2. Start the Local Bridge

Run the launcher for your operating system:

| Operating System | Recommended Command / Script | Alternative |
|---|---|---|
| **Linux** | `./start_zed.sh` | `bash Linux_Start.sh` |
| **macOS** | `./start_zed.sh` | Double-click `MacOS_Start.command` |
| **Windows** | `start_zed.bat` | Double-click `start.bat` |

The launcher will:
- Verify Python 3.9+ and dependencies (`websockets`).
- Auto-configure MCP servers (`vscode_mcp.py` & `zed_mcp.py`).
- Start the WebSocket bridge on `ws://127.0.0.1:17613`.
- Start the OpenAI reverse proxy on `http://127.0.0.1:17614/v1`.

---

## 📐 Editor Setup

### Option A: Using with Zed Editor

You can chat with the AI directly from Zed Editor's Assistant panel without ever touching the browser window!

#### 1. Configure Zed `settings.json`
Open your Zed configuration file:
- **Linux**: `~/.config/zed/settings.json`
- **macOS**: `~/Library/Application Support/Zed/settings.json`
- **Windows**: `%APPDATA%\Zed\settings.json`

Add the `language_models` block:

```json
{
  "language_models": {
    "openai": {
      "api_url": "http://127.0.0.1:17614/v1",
      "available_models": [
        {
          "name": "deepseek-web",
          "display_name": "Snapgent DeepSeek (Web Free)",
          "max_tokens": 16384
        },
        {
          "name": "qwen-web",
          "display_name": "Snapgent Qwen (Web Free)",
          "max_tokens": 16384
        }
      ]
    }
  }
}
```

#### 2. Start Chatting in Zed
1. Ensure the bridge is running (`./start_zed.sh` or `start_zed.bat`).
2. Keep a browser tab open with `https://chat.deepseek.com` or `https://chat.qwen.ai` logged in.
3. In Zed Editor, open the Assistant panel (`Ctrl + ?` or `Cmd + ?`).
4. Select model: **Snapgent DeepSeek (Web Free)** or **Snapgent Qwen (Web Free)**.
5. Ask your prompt! The AI uses prefix-aware commands like `zededitor/read_file` to interact with your workspace.

---

### Option B: Using with VS Code

1. Open your target project folder in **VS Code**.
2. Make sure the bridge is running (`./start_zed.sh` or `start.bat`).
3. In the browser extension or on the AI chat page (e.g. DeepSeek / Claude / ChatGPT):
   - Choose **VS Code** in the MCP target dropdown.
   - Click **Start session**.
4. The AI will interact with your VS Code project using `vscode/*` tools.

---

## 🏗️ How it Works

```
┌────────────────────────────────┐
│   Web AI Chat (Browser Tab)    │
│  DeepSeek / Qwen / Claude / .. │
└───────────────▲────────────────┘
                │ DOM / Extension
┌───────────────▼────────────────┐         WebSocket
│    Agent Browser Extension     │ ───────────────────────┐
│     (Chrome / Edge MV3)        │                        │
└────────────────────────────────┘                        │
                                                          ▼
┌───────────────────────────────┐     HTTP (OpenAI)    ┌───────────────────────────┐
│          Zed Editor           │ ◀──────────────────▶ │  Snapgent Local Bridge    │
│  (Assistant / Agent Panel)    │      port 17614      │   • WebSocket: port 17613 │
└───────────────────────────────┘                      │   • OpenAI Proxy: 17614   │
                                                       └─────────────▲─────────────┘
                                                                     │ Stdio MCP
                                                       ┌─────────────▼─────────────┐
                                                       │   Local MCP Servers       │
                                                       │  • vscode_mcp (28 tools)  │
                                                       │  • zed_mcp    (28 tools)  │
                                                       └───────────────────────────┘
```

---

## 🌐 Supported AI Providers (In Browser)

| Provider | URL | Status | Recommended For |
|---|---|---|---|
| **DeepSeek** | `chat.deepseek.com` | ✅ Supported | **Best performance & speed** |
| **Qwen** | `chat.qwen.ai` | ✅ Supported | **Excellent coding capability** |
| **ChatGPT** | `chatgpt.com` | ✅ Supported | General coding |
| **Claude** | `claude.ai` | ✅ Supported | Complex reasoning |
| **Google Gemini** | `gemini.google.com` | ✅ Supported | Multimodal tasks |
| **Kimi** | `kimi.ai` | ✅ Supported | Fast response |
| **Grok** | `grok.com` | ✅ Supported | Requires xAI sign-in |
| **GLM (Z.ai)** | `chat.z.ai` | ✅ Supported | Multilingual |
| **Arena** | `arena.ai` | ✅ Supported | Model benchmarking (Use Direct mode) |
| **Meta AI** | `meta.ai` | ✅ Supported | General tasks |
| **Ptero** | `ptero.pro` | ✅ Supported | Privacy-focused |
| **Mistral** | `chat.mistral.ai` | 🧪 Experimental | Open weights models |

---

## 📂 Project Structure

```
agent-browser/
├── snapgent-extension/        # Browser extension (Chrome / Edge MV3)
│   ├── core/                  # Prompt engine, parser, agent loop, UI
│   │   ├── config.js          # Dynamic prefixes (vscode/ vs zededitor/)
│   │   ├── parser.js          # Command parsing
│   │   └── main.js            # Agent loop & UI bar
│   ├── providers/             # Per-AI DOM selectors & stream handlers
│   ├── popup.html             # Status popup & Zed setup guide
│   └── manifest.json          # Extension manifest V3
├── bridge.py                  # Core bridge (WebSocket + OpenAI reverse proxy)
├── vscode_mcp.py              # VS Code MCP server (28 tools)
├── zed_mcp.py                 # Zed Editor MCP server (28 tools)
├── setup-config.py            # Cross-platform MCP configuration generator
├── start_zed.sh               # Linux & macOS unified startup script
├── start_zed.bat              # Windows unified startup script
├── Linux_Start.sh             # Linux bridge launcher
├── MacOS_Start.command        # macOS bridge launcher
└── start.bat                  # Windows bridge launcher
```

---

## ❓ Troubleshooting

| Issue | Cause | Solution |
|---|---|---|
| **Bridge Offline** in extension | Bridge process is not running | Run `./start_zed.sh` (Linux/Mac) or `start_zed.bat` (Windows). |
| **Zed: "No models available"** | `settings.json` missing or port 17614 blocked | Verify `language_models` in Zed's `settings.json` points to `http://127.0.0.1:17614/v1`. |
| **Tool calling fails with "Unknown tool"** | Outdated config or wrong prefix | Ensure you use `vscode/*` when VS Code is selected, or `zededitor/*` when Zed Editor is selected. |
| **AI stops executing commands** | Context window reached or model lost prompt | Send a short prompt: *"Continue using tools to complete the task"*, or start a fresh chat tab. |

---

## 📜 License

Licensed under the **GPL-3.0 License**. See [LICENSE](LICENSE) for details.

Repository: [https://github.com/robyajo/agent-browser](https://github.com/robyajo/agent-browser)
