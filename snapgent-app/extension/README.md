# Agent Browser - Free AI Coding Agent for VS Code & Zed Editor

Turn web AI chatbots (**DeepSeek**, **Qwen**, **ChatGPT**, **Claude**, **Google Gemini**, **Grok**, **Kimi**, **GLM**, **Arena**, **Meta AI**, or **Ptero**) into powerful coding agents directly inside **VS Code** and **Zed Editor** without API keys, subscriptions, or credit cards.

Just describe what you want in chat, and the agent reads workspace files, edits code, lists directory trees, and inspects files directly in your local editor.

## Key Features

- **Dual Editor Support**:
  - **VS Code**: Uses `vscode/*` tools (e.g. `vscode/read_file`, `vscode/write_file`, 28 workspace tools).
  - **Zed Editor**: Uses `zededitor/*` tools (e.g. `zededitor/read_file`, `zededitor/write_file`, 28 workspace tools).
- **Free Web Models**: Use cutting-edge free web models (DeepSeek-V3 / R1, Qwen 2.5 Max / Coder) directly or connect Zed Editor to the local OpenAI-compatible reverse proxy (`http://127.0.0.1:17614/v1`).
- **No API Keys Needed**: Interacts through your existing browser session.

## Setup

### 1. Load the extension (Chrome / Edge / Brave)
1. Go to `chrome://extensions` or `edge://extensions`.
2. Enable **Developer mode** (top-right toggle).
3. Click **Load unpacked**.
4. Select the `snapgent-extension` folder.

### 2. Start the Local Bridge
- **Linux & macOS**: Run `./start_zed.sh` (or `Linux_Start.sh` / `MacOS_Start.command`).
- **Windows**: Double-click `start_zed.bat` (or `start.bat`).

### 3. Open Your Editor & Start Coding!
- **For VS Code**: Open your project workspace in VS Code, choose **VS Code** in the extension target menu, open your preferred AI chat tab (e.g., https://chat.deepseek.com or https://chat.qwen.ai), and click **Start**.
- **For Zed Editor**: Open your project in Zed Editor, configure `settings.json` (see instructions in repository README), open the Zed Assistant panel, and select **Snapgent DeepSeek (Web Free)** or **Snapgent Qwen (Web Free)**.

## Architecture

The extension is split between a provider-agnostic core and per-AI-site providers:

```
core/config.js        system prompt, dynamic prefixing (vscode/ vs zededitor/), tool categories
core/parser.js        command parsing - pure string logic
core/main.js          agentic loop, UI, session state
providers/deepseek.js DeepSeek web chat integration
providers/qwen.js     Qwen web chat integration
providers/claude.js   Claude web chat integration
providers/chatgpt.js  ChatGPT web chat integration
providers/...         Gemini, Grok, Kimi, GLM, Arena, Meta AI, Ptero, Mistral
background.js         WebSocket to local bridge (port 17613) and tab router
```

Repository: [https://github.com/robyajo/agent-browser](https://github.com/robyajo/agent-browser)
