import { spawn } from "node:child_process";
import os from "node:os";
import path from "node:path";

const SESSION_METHODS = new Set([
  "session/new",
  "session/load",
  "session/resume",
]);
const DISABLED_TOOL = "run_workflow";

function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parseDisabledTools(value) {
  if (Array.isArray(value)) {
    return value.map((item) => String(item));
  }
  if (typeof value === "string") {
    return value
      .split(",")
      .map((token) => token.trim())
      .filter((token) => token.length > 0);
  }
  return [];
}

function rewriteMessageLine(line) {
  if (!line.includes("session/")) {
    return line;
  }

  let message;
  try {
    message = JSON.parse(line);
  } catch {
    return line;
  }

  if (
    !isPlainObject(message) ||
    !SESSION_METHODS.has(message.method) ||
    !isPlainObject(message.params)
  ) {
    return line;
  }

  const meta = isPlainObject(message.params._meta)
    ? { ...message.params._meta }
    : {};
  const antigravity = isPlainObject(meta.antigravity)
    ? { ...meta.antigravity }
    : {};
  const disabledTools = parseDisabledTools(antigravity.disabledTools);

  if (!disabledTools.includes(DISABLED_TOOL)) {
    disabledTools.push(DISABLED_TOOL);
  }

  antigravity.disabledTools = disabledTools;
  meta.antigravity = antigravity;
  message.params = {
    ...message.params,
    _meta: meta,
  };

  return JSON.stringify(message);
}

const serverBin = path.join(
  os.homedir(),
  ".local",
  "opt",
  "agy-acp",
  "current",
  "agy_acp_server.par",
);
const forwardedArgs = process.argv.slice(2);
const serverArgs =
  process.platform === "linux" && !forwardedArgs.includes("--uid=")
    ? ["--uid=", ...forwardedArgs]
    : forwardedArgs;

// Keep the child in the same process group so pi-antigravity-acp-provider's
// supervisor kills both the wrapper and agy_acp_server.par together.
const child = spawn(serverBin, serverArgs, {
  stdio: ["pipe", "pipe", "pipe"],
  shell: false,
  env: process.env,
});

child.stdout.pipe(process.stdout);
child.stderr.pipe(process.stderr);

child.stdin.on("error", (error) => {
  if (error.code === "EPIPE" || error.code === "ERR_STREAM_DESTROYED") {
    return;
  }
  throw error;
});

child.once("error", (error) => {
  const hint =
    error.code === "ENOENT"
      ? " Run Pi once with AGY_ACP_BIN unset so pi-antigravity-acp-provider installs the managed server."
      : "";
  process.stderr.write(
    `agy-acp-wrapper: failed to start ${serverBin}: ${error.message}.${hint}\n`,
  );
  process.exit(1);
});

child.once("exit", (code, signal) => {
  process.stdin.destroy();
  const exitCode = code ?? (signal ? 1 : 0);
  process.stdout.end(() => {
    process.exit(exitCode);
  });
});

for (const signal of ["SIGTERM", "SIGINT", "SIGHUP"]) {
  process.once(signal, () => {
    try {
      child.kill(signal);
    } catch (error) {
      if (error.code !== "ESRCH") {
        throw error;
      }
    }
  });
}

let pending = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  pending += chunk;
  const lines = pending.split("\n");
  pending = lines.pop() ?? "";
  for (const rawLine of lines) {
    const line = rawLine.endsWith("\r") ? rawLine.slice(0, -1) : rawLine;
    child.stdin.write(`${rewriteMessageLine(line)}\n`);
  }
});

process.stdin.once("end", () => {
  if (pending.length > 0) {
    const line = pending.endsWith("\r") ? pending.slice(0, -1) : pending;
    child.stdin.write(`${rewriteMessageLine(line)}\n`);
    pending = "";
  }
  child.stdin.end();
});
