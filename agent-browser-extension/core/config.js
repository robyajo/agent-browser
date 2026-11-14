// SPDX-License-Identifier: GPL-3.0-or-later
// core/config.js - provider-agnostic constants: app identity, system prompt,
// feedback strings, tool categorisation. NOTHING in this file may reference a
// specific AI site (DOM, selectors, site names) - that lives in providers/*.
// eslint-disable-next-line no-unused-vars
const ZS = (() => {
  "use strict";

  // Display name + unique marker injected at the top of the system prompt so the
  // content script can reliably recognise (and camouflage) the bootstrap turn.
  const APP_NAME = "agent-browser";
  const SYS_MARKER = "⟦ZS-SYS⟧";
  // A re-statement of the system prompt mid-session (see withSysResend in
  // core/main.js). It carries SYS_MARKER TOO - that is what drives camouflage
  // and session detection, and neither should change - plus this second marker,
  // purely so the chip can say "Reminder" instead of inheriting the bootstrap's
  // "Starting Up". Same content, different label: a re-injection is not a start.
  const RESEND_MARKER = "⟦ZS-RE⟧";

  // ── Tool → visual category (icon + colour theme for the chips) ─────────
  // Returns one of: read | edit | tool
  function toolCategory(name) {
    const n = (name || "").includes("/") ? name.split("/").pop() : (name || "");
    if (/^(read_file|list_dir|file_search|grep_search|git_status|git_diff|git_log|list_commands|list_tools)$/.test(n))
      return "read";
    if (/^(write_file|edit_file|patch_file|delete_file|create_directory|git_commit|git_add)$/.test(n))
      return "edit";
    return "tool";
  }

  // Feedback strings sent back to the model so it can self-correct.
  const FEEDBACK = {
    // A command-shaped reply that could not be turned into a runnable call.
    // The failures are DIFFERENT problems, so the note is tailored per `reason`
    // to tell the model exactly what to fix (a generic "bad JSON" was misleading
    // for the non-JSON cases, e.g. a missing ###LUA### opener). Falls back to the
    // generic "malformed" text for any unrecognised reason.
    parseError: (reason, toolName) => {
      // ###LUA### is execute_luau-ONLY (the parser always maps a bare ###LUA###
      // block to execute_luau). So only suggest it when the broken command IS
      // execute_luau, or when we could not tell which command it was. For a KNOWN
      // other command (e.g. execute_blender_code) the ###LUA### hint is wrong and
      // misleading - a model that followed it would ship its code to the wrong MCP
      // - so drop it and keep the JSON-only guidance.
      const otherCmd = toolName && toolName !== "command" && toolName !== "execute_luau";
      const luaMalformed = otherCmd ? "" : " (or use the ###LUA### / ###END_LUA### block for execute_luau)";
      const luaUnclosed = otherCmd ? "" : " (or a complete ###LUA### ... ###END_LUA### block for execute_luau)";
      const objAlt = otherCmd ? "" : " (or ###...### block)";
      const notes = {
        malformed:
          "ERROR: an Agent Browser command was detected in your reply but its JSON could not be parsed. " +
          'Rewrite it as a single valid JSON object in plain text, exactly like {"command": "name", "params": {...}}' +
          luaMalformed + ". You may add a short note around it. " +
          "Please retry.",
        unclosed:
          "ERROR: your Agent Browser command was cut off before it finished - the JSON object" +
          objAlt + " never closed, so it could not run. Rewrite the WHOLE command in one " +
          'piece as valid JSON, exactly like {"command": "name", "params": {...}}' +
          luaUnclosed + ". Please retry.",
        luaOpener:
          "ERROR: you wrote the closing ###END_LUA### marker but not the opening ###LUA### marker, " +
          "so the Luau block was not detected and did not run. Put ###LUA### immediately BEFORE your " +
          "code and ###END_LUA### after it. Please retry.",
        envelope:
          "ERROR: you wrote a command's parameters as a bare JSON object, but without the required " +
          "envelope, so it was not recognised as a command. Wrap them like " +
          '{"command": "name", "params": { ...your parameters... }} - the parameter keys go INSIDE ' +
          '"params". Please retry.',
        // The model named a REAL tool but under the wrong key - it wrote the call
        // the way a function-calling API would (e.g. {"toolName": "get_studio_state",
        // "studio_id": "..."}) instead of Agent Browser's envelope. Seen live on
        // ChatGPT in a long session. Naming the wrong keys explicitly matters: a
        // generic "bad JSON" note made the model rewrite the SAME shape.
        toolKey:
          "ERROR: you used the wrong key to name the command, so it was not recognised and did not " +
          'run. The key must be exactly "command" - not "toolName", "tool", "name", "function" or ' +
          '"action" - and every argument goes INSIDE "params", like ' +
          '{"command": "name", "params": { ...your parameters... }}. Please retry.',
        // DeepSeek sometimes falls back to its own native agentic markup. The
        // note must NEVER quote the markers literally: the reply that follows
        // often echoes the wording, and a quoted marker would re-trigger the
        // detector and loop the error forever. Describe it, don't reproduce it.
        dsml:
          "ERROR: you wrote that call in your own internal tool-call markup (the DSML invoke/parameter " +
          "tags). Agent Browser cannot read that format, so the command did not run. Never use those tags " +
          "here. Write the call as a single plain-text JSON object instead, exactly like " +
          '{"command": "name", "params": { ...your parameters... }} - one command per reply. ' +
          "Please retry.",
      };
      return notes[reason] || notes.malformed;
    },
    multiTool: (names) =>
      "ERROR: You wrote multiple commands in one reply. Write ONE command at a " +
      "time and wait for its result before the next. You tried: " +
      names.join(", ") +
      ". Start over and write only the first command you need.",
    unknownTool: (name, valid) =>
      `ERROR: unknown command "${name}". It does not exist. Valid commands are: ` +
      valid.join(", ") +
      ". Use an exact name and parameter keys from the system prompt.",
    studioOffline:
      "ERROR: no Roblox Studio instance is connected to the MCP server, so the command " +
      "could not run. Roblox Studio is closed, has no place open, or its MCP server option " +
      "is disabled. This is an environment problem on the user's machine, NOT your mistake. " +
      "Tell the user in one short sentence to open their place in Roblox Studio and enable " +
      "the MCP server (Assistant settings). Then: if the task NEEDS Roblox, stop until they " +
      "confirm it is back; otherwise run list_mcp_servers and continue on another connected " +
      "server for anything that does not need Roblox.",
    // The page outlived the extension build it was running (reload / auto-update
    // / disable+enable). Nothing here can recover it - only a page reload can -
    // so the model must NOT be told the bridge is down and must NOT retry, or it
    // burns the whole conversation re-issuing commands that can never run. See
    // isContextInvalidated in core/main.js.
    staleExtension:
      "ERROR: the Agent Browser extension was reloaded or updated while this page was open, so this " +
      "tab is running a version of it that no longer exists and NO command can reach the user's " +
      "machine from here. The bridge and editor are NOT the problem - do not tell the user " +
      "to check them, and do not retry the command, because every retry will fail the same way. " +
      "Tell the user in one short sentence to RELOAD THIS PAGE (F5), then stop and wait.",
    bridgeOffline:
      "ERROR: the local Agent Browser bridge is unreachable, so no command could run. " +
      "This is an environment problem on the user's machine (the bridge is not " +
      "running, or the target editor is closed), NOT your mistake. Tell the user in " +
      "one short sentence that the bridge or editor is offline, then stop " +
      "sending commands until they confirm it is back.",
    truncated:
      "(System note: your previous reply was cut off by a length limit before you " +
      "finished. Continue from exactly where you stopped. Do NOT restart and do " +
      "NOT repeat what you already wrote.)",
  };

  const BT = "```";

  function compactTools(tools, prefix = "") {
    const pfx = prefix ? `${prefix}/` : "";
    return (tools || [])
      .map((t) => {
        let name = t.name || "?";
        if (pfx && !name.includes("/")) {
          name = `${pfx}${name}`;
        }
        const desc = (t.description || "").split("\n")[0].trim();
        const props = (t.inputSchema && t.inputSchema.properties) || {};
        const args = Object.keys(props).join(", ");
        return `  ${name}(${args}) - ${desc}`;
      })
      .join("\n");
  }

  // ── System prompt ─────────────────────────────────────────────────────────
  // ONE unified prompt sent to every AI on the first turn. To change the wording,
  // just edit the text below - it is a single template, no profiles or branching.
  // `${siteName}` is filled in with the AI's display name (e.g. "DeepSeek").
  // `${toolsString}` is filled in with the live command list.
  //
  // `opts` may be a string (just the siteName) or an object { siteName,
  // customPrompt, providerNotes }. `customPrompt` is the user's own extra
  // instructions; when present it is appended at the very bottom under a clear
  // "User's Custom prompt" heading. It NEVER edits the prompt above - it only
  // adds a layer below it.
  //
  // `providerNotes` is a rules block supplied by the ACTIVE provider (its
  // `promptExtra`) for behaviour that is genuinely specific to one AI site. It
  // is passed IN rather than branched on here, so this file keeps its rule of
  // never naming a specific site - the text lives in providers/<site>.js and
  // every other provider is untouched by definition.
  function buildSystemPrompt(opts = {}) {
    if (typeof opts === "string") opts = { siteName: opts };
    const {
      siteName = "this AI site",
      customPrompt = "",
      providerNotes = "",
      targetServer = "vscode",
      targetName = "VS Code",
      skills = [],
    } = opts;

    const isZed = targetServer === "zededitor" || targetServer === "zed";
    const prefix = isZed ? "zededitor" : "vscode";
    const displayName = isZed ? "Zed Editor" : "VS Code";
    const exampleTool = `${prefix}/read_file`;

    const prompt = `CONTEXT: Agent Browser is a browser extension that connects your plain-text JSON commands to the user's code editor through their local bridge.
Selected active editor target: ${displayName} (command prefix: "${prefix}/").

The extension reads commands from your normal reply text and executes them in ${displayName}.
Your built-in tools or web sandbox do NOT access the user's local machine or editor workspace.
For working on the user's project in ${displayName}, write exactly one command per reply as a fenced JSON block:

\`\`\`json
{"command":"${exampleTool}","params":{"path":"README.md"}}
\`\`\`

IMPORTANT INSTRUCTION FOR COMMAND NAMES:
- All commands for ${displayName} MUST be prefixed with "${prefix}/" (for example: "${prefix}/read_file", "${prefix}/write_file", "${prefix}/edit_file", "${prefix}/list_dir", "${prefix}/run_command").
- At the start of the session, call \`list_commands\` with server "${prefix}" to get the exact available tools and parameter schemas. Use only names and parameters from that result. Do not assume tools are available. If the needed tool is missing or the server is offline, explain that clearly and do not claim the task is complete. Do not call tools on another server unless the user asks to switch targets.

Rules:
- Execute one command at a time and wait for its result before writing another.
- Put every command in a fenced JSON code block; do not use native function calls.
- Respect the user's requested workspace and file scope. Never perform broad or destructive changes without explicit confirmation.
- On errors, use the returned error to adjust the next command; do not silently claim success.
- When finished, summarize the completed work briefly.
- You are ${siteName}; Agent Browser carries out the commands on ${displayName}.`;

    const skillsBlock = Array.isArray(skills) && skills.length
      ? "\n\nAvailable skills (reusable instructions stored in the workspace). When a task matches a skill's description, first read its SKILL.md with read_file, then follow it. Skills are guidance only: never run a skill's scripts without the user's confirmation.\n" +
        skills.map((s) => `- ${s.name}: ${s.description} (path: ${s.path || ".agent-browser/skills/" + s.name + "/SKILL.md"})`).join("\n")
      : "";

    const siteRules = providerNotes.trim()
      ? `\n\n━━━ ADDITIONAL RULES FOR THIS SITE ━━━\n${providerNotes.trim()}`
      : "";

    const extra = customPrompt.trim()
      ? `\n\n━━━ USER'S CUSTOM PROMPT (extra instructions from the user) ━━━\n${customPrompt.trim()}`
      : "";

    return `${SYS_MARKER}\n${prompt}${skillsBlock}${siteRules}${extra}`;
  }

  const TOOL_NOTES = {
    read_file: "Reads file content. Path is relative to the active workspace folder.",
    write_file: "Writes full content to file. Path is relative to the active workspace folder.",
    edit_file: "Edits file content by replacing old_text with new_text. old_text must match exactly.",
    list_dir: "Lists directory entries. Defaults to current workspace root ('.').",
    run_command: "Runs a command in the workspace directory with bash/sh.",
  };

  function toolsReminder(tools, targetName = "VS Code", serverId = "vscode") {
    const isZed = serverId === "zededitor" || serverId === "zed";
    const prefix = isZed ? "zededitor" : "vscode";
    const displayName = isZed ? "Zed Editor" : "VS Code";
    const toolsString =
      `  list_commands(server: "${prefix}") - list available ${displayName} commands with full parameter details\n` +
      compactTools(tools, prefix);
    return (
      "\n\n────────────────────────────────\n" +
      "(System note from Agent Browser - this is an automatic REMINDER, not a request and not a new result. " +
      "Do NOT reply to it or run any command because of it; just keep it in mind for your next command.)\n" +
      `Reminder of ${displayName} commands (MUST use the "${prefix}/" prefix, e.g. ${prefix}/read_file):\n` +
      toolsString
    );
  }

  function memoryNudge() {
    return "";
  }

  return {
    APP_NAME,
    SYS_MARKER,
    RESEND_MARKER,
    FEEDBACK,
    toolCategory,
    buildSystemPrompt,
    compactTools,
    toolsReminder,
    memoryNudge,
    TOOL_NOTES,
  };
})();
