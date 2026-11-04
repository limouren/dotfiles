-- Send a phone notification through ntfy when a terminal needs attention.
--
-- A Rex app owns the panes it shows, and Rex.app on the Mac keeps owning them
-- and notifies about them itself. So only a pane without an owner needs ntfy.
--
-- Usage: rex do --all notify.lua topic=TOPIC [server=URL]

local topic = rex.args.topic
if not topic then
  error("usage: rex do --all notify.lua topic=TOPIC [server=URL]", 0)
end
local server = rex.args.server or "https://ntfy.sh"

local terminal = "com.superlogical.terminal"
-- Programs such as shells ring the bell often, so each block sends at most one
-- notification of each kind in this period.
local quiet_seconds = 30

local last_sent = {}

local function block_info(ctx)
  local blocks = rex.session.list_blocks{}
  local view = rex.session.view{}
  local session_label = view and view.label or ctx.session_id
  if blocks then
    for _, block in ipairs(blocks.blocks) do
      if block.block_id == ctx.block_id then
        return session_label, block.label, block.owner
      end
    end
  end
  return session_label, nil, nil
end

local function send(ctx, kind, title, body, priority)
  local session_label, block_label, owner = block_info(ctx)
  if owner then
    return
  end

  local key = ctx.block_id .. " " .. kind
  local now = os.time()
  if last_sent[key] and now - last_sent[key] < quiet_seconds then
    return
  end
  last_sent[key] = now

  local where = session_label
  if block_label then
    where = where .. " · " .. block_label
  end
  local message = rex.json.encode({
    topic = topic,
    title = where .. ": " .. title,
    message = body ~= "" and body or title,
    priority = priority or 3,
    tags = { kind },
  })
  local result, err = rex.exec({
    "curl", "-sS", "--fail-with-body", "--max-time", "10",
    "--data-binary", "@-",
    server,
  }, { stdin = message })
  if not result then
    rex.log("error", "ntfy: " .. err)
  elseif not result.ok then
    rex.log("error", "ntfy: " .. result.stderr)
  end
end

local status_titles = {
  blocked = "needs you",
  done = "done",
  error = "failed",
}

rex.on("terminal.program_status_changed", function(ctx, ev)
  local record = ev.record
  local title = status_titles[record.state]
  if not title then
    return
  end
  local app = record.effective_app or record.app or "program"
  local priority = record.state == "blocked" and 4 or 3
  send(ctx, record.state, app .. " " .. title, record.msg or "", priority)
end)

rex.on("terminal.desktop_notification", function(ctx, ev)
  local title = ev.title ~= "" and ev.title or "notification"
  send(ctx, "notification", title, ev.body or "")
end)

rex.on("terminal.bell", function(ctx, ev)
  local process = rex.block.call(terminal, "process", { block_id = ctx.block_id })
  -- A bell from the shell itself is usually tab completion, not a request.
  if not process or not process.foreground or process.foreground.pid == process.child.pid then
    return
  end
  send(ctx, "bell", process.foreground.name .. " rang the bell", "")
end)
