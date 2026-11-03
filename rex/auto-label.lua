-- Label each Rex session after the project most of its terminals are in.
--
-- Usage: rex do auto-label.lua --all
--
-- Run outside a session (as under systemd), it also labels every session at
-- start and each new session when it is created. Run inside one, it labels
-- only that session at start.
--
-- A label the script did not set pins the session. Rename a session to "auto"
-- to unpin it.

local terminal = "com.superlogical.terminal"
local show_branch = true
local debounce_seconds = 0.5
local unpin_label = "auto"

local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))
  .. "/rex-auto-label"
local state_path = state_dir .. "/state.json"

local function load_state()
  local file = io.open(state_path, "r")
  if not file then
    return { sessions = {} }
  end
  local text = file:read("*a")
  file:close()
  local state = rex.json.decode(text)
  if type(state) ~= "table" or type(state.sessions) ~= "table" then
    rex.log("warn", "auto-label: ignoring unreadable " .. state_path)
    return { sessions = {} }
  end
  return state
end

local state = load_state()

local function save_state()
  rex.exec({ "mkdir", "-p", state_dir })
  local tmp = state_path .. ".tmp"
  local file = assert(io.open(tmp, "w"))
  file:write(assert(rex.json.encode(state, { indent = true })))
  file:close()
  assert(os.rename(tmp, state_path))
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function basename(path)
  return path:match("([^/]+)/*$") or path
end

-- macOS realpath has no -e, so resolve with pwd -P, which fails for a
-- missing directory.
local function realpath(path)
  local r = rex.exec({ "pwd", "-P" }, { cwd = path, timeout = 5 })
  if r and r.ok then
    return trim(r.stdout)
  end
  return nil
end

local real_home
local function home()
  if not real_home then
    real_home = realpath(os.getenv("HOME")) or os.getenv("HOME")
  end
  return real_home
end

local function git(dir, args)
  local argv = { "git", "-C", dir }
  for _, a in ipairs(args) do
    table.insert(argv, a)
  end
  local r = rex.exec(argv, { timeout = 5 })
  if r and r.ok then
    return r.stdout
  end
  return nil
end

local function url_to_path(pwd)
  local path = pwd:gsub("^file://[^/]*", "")
  return (path:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

local function pane_dir(session_id, block_id)
  local where = { session_id = session_id, block_id = block_id }
  local reported = rex.block.call(terminal, "pwd", where)
  if reported and reported.pwd and reported.pwd ~= "" then
    return url_to_path(reported.pwd)
  end
  local process = rex.block.call(terminal, "process", where)
  if not process then
    return nil
  end
  local program = process.foreground or process.child
  return program and program.cwd
end

-- Returns { key, base, branch, worktree } for a directory, or nil when the
-- directory does not exist on this machine. key is nil for $HOME.
local function classify(dir)
  local out = git(dir, {
    "rev-parse", "--path-format=absolute",
    "--show-toplevel", "--git-dir", "--git-common-dir", "--abbrev-ref", "HEAD",
  })
  if out then
    local top, git_dir, common_dir, branch = out:match("^([^\n]*)\n([^\n]*)\n([^\n]*)\n([^\n]*)")
    if top then
      if top == home() then
        return { key = nil }
      end
      local repo = common_dir:match("^(.*)/%.git/?$")
      local base = repo and basename(repo) or basename(common_dir):gsub("%.git$", "")
      return {
        key = top,
        base = base,
        branch = branch ~= "HEAD" and branch or nil,
        worktree = git_dir ~= common_dir,
        top = top,
      }
    end
  end
  local real = realpath(dir)
  if not real then
    return nil
  end
  if real == home() then
    return { key = nil }
  end
  return { key = real, base = basename(real) }
end

local function default_branch(top)
  local origin = git(top, { "symbolic-ref", "--short", "-q", "refs/remotes/origin/HEAD" })
  if origin and trim(origin) ~= "" then
    return (trim(origin):gsub("^[^/]+/", ""))
  end
  for _, name in ipairs({ "main", "master" }) do
    if git(top, { "show-ref", "--verify", "--quiet", "refs/heads/" .. name }) then
      return name
    end
  end
  return nil
end

local function project_label(info)
  if show_branch and info.branch then
    if info.worktree or info.branch ~= default_branch(info.top) then
      return info.base .. "@" .. info.branch
    end
  end
  return info.base
end

-- Returns the label for the winning project, or nil to leave the label alone.
local function desired_label(session_id, view)
  local focused
  for _, w in ipairs(view.windows or {}) do
    if w.window_id == view.active_window_id then
      focused = w.focused_block_id
    end
  end

  local cache = {}
  local votes = {}
  local panes = {}
  for _, w in ipairs(view.windows or {}) do
    for _, layer in ipairs(w.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.creator_name == terminal then
          local dir = pane_dir(session_id, block.block_id)
          if dir then
            if cache[dir] == nil then
              cache[dir] = classify(dir) or false
            end
            local info = cache[dir]
            if info then
              local key = info.key or "~"
              votes[key] = (votes[key] or 0) + 1
              table.insert(panes, { block_id = block.block_id, key = key, info = info })
            end
          end
        end
      end
    end
  end

  local most = 0
  for _, n in pairs(votes) do
    if n > most then
      most = n
    end
  end
  if most == 0 then
    return nil
  end

  local winner
  for _, pane in ipairs(panes) do
    if pane.block_id == focused and votes[pane.key] == most then
      winner = pane
    end
  end
  if not winner then
    for _, pane in ipairs(panes) do
      if votes[pane.key] == most then
        winner = pane
        break
      end
    end
  end
  if winner.key == "~" then
    return "~"
  end
  return project_label(winner.info)
end

-- Duplicate labels make Rex CLI targets ambiguous, so add -2, -3, ...
local function unique_label(session_id, base, current)
  local list = rex.call("session.list")
  local taken = {}
  for _, s in ipairs(list and list.sessions or {}) do
    if s.session_id ~= session_id then
      taken[s.label] = true
    end
  end
  local suffix = current:sub(#base + 1):match("^%-(%d+)$")
  local is_variant = current == base
    or (current:sub(1, #base) == base and suffix and tonumber(suffix) >= 2)
  if is_variant and not taken[current] then
    return current
  end
  if not taken[base] then
    return base
  end
  local n = 2
  while taken[base .. "-" .. n] do
    n = n + 1
  end
  return base .. "-" .. n
end

local function set_label(session_id, label)
  local _, err = rex.session.set_label{ session_id = session_id, label = label }
  if err then
    rex.log("error", "auto-label: set_label " .. session_id .. ": " .. err)
    return false
  end
  return true
end

local function current_label(session_id)
  local view = rex.session.view{ session_id = session_id }
  return view and view.label
end

-- An empty label restores the label the server chose. If that equals the
-- current label, nobody named the session yet.
local function probe(session_id, label)
  if not set_label(session_id, "") then
    return nil
  end
  local restored = current_label(session_id)
  if restored == label then
    return { expected = label, pinned = false }
  end
  set_label(session_id, label)
  rex.log("info", "auto-label: pinned " .. label)
  return { expected = label, pinned = true }
end

local function relabel(session_id)
  local view = rex.session.view{ session_id = session_id }
  if not view then
    return
  end
  local label = view.label
  local entry = state.sessions[session_id]

  if label == unpin_label then
    entry = { pinned = false }
  elseif not entry then
    entry = probe(session_id, label)
    if not entry then
      return
    end
    if entry.pinned then
      state.sessions[session_id] = entry
      save_state()
      return
    end
  elseif entry.pinned then
    return
  elseif label ~= entry.expected then
    entry.pinned = true
    state.sessions[session_id] = entry
    save_state()
    rex.log("info", "auto-label: pinned " .. label)
    return
  end

  local base = desired_label(session_id, view)
  if base then
    local want = unique_label(session_id, base, label)
    if want ~= label and set_label(session_id, want) then
      rex.log("info", "auto-label: " .. label .. " -> " .. want)
      label = want
    end
  elseif label == unpin_label and set_label(session_id, "") then
    label = current_label(session_id) or label
  end
  entry.expected = label
  state.sessions[session_id] = entry
  save_state()
end

local pending = {}

local function schedule(session_id)
  if not session_id then
    return
  end
  if pending[session_id] then
    pending[session_id]:cancel()
  end
  pending[session_id] = rex.after(debounce_seconds, function()
    pending[session_id] = nil
    relabel(session_id)
  end)
end

local function on_session_event(ctx)
  schedule(ctx.session_id)
end

rex.on("session_view_changed", on_session_event)
rex.on("terminal.pwd_changed", on_session_event)
-- No event reports a branch switch, but the shell's foreground process
-- changes when git exits.
rex.on("terminal.process_changed", on_session_event)

-- A script started with -s hears session_created for every session.
rex.on("session_created", function(ctx, ev)
  if not rex.session_id then
    schedule(ev.session and ev.session.session_id)
  end
end)

rex.on("session_destroyed", function(ctx, ev)
  local id = ev.session_id or ctx.session_id
  if pending[id] then
    pending[id]:cancel()
    pending[id] = nil
  end
  if state.sessions[id] then
    state.sessions[id] = nil
    save_state()
  end
end)

rex.after(0, function()
  if rex.session_id then
    schedule(rex.session_id)
    return
  end
  local list, err = rex.call("session.list")
  if not list then
    rex.log("error", "auto-label: session.list: " .. tostring(err))
    return
  end
  local alive = {}
  for _, s in ipairs(list.sessions or {}) do
    alive[s.session_id] = true
    schedule(s.session_id)
  end
  for id in pairs(state.sessions) do
    if not alive[id] then
      state.sessions[id] = nil
    end
  end
  save_state()
end)
