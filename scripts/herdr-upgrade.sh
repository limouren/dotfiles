#!/usr/bin/env bash
#
# Move the herdr server to HERDR_BIN without killing pane processes.
# Runs after every home-manager switch.

set -euo pipefail

readonly UNIT="${HERDR_UPGRADE_UNIT:-herdr.service}"
readonly IDLE_POLL_SECONDS=30
# A failed handoff takes up to 32 seconds to restore the old server's sockets.
readonly HANDOFF_SETTLE_SECONDS=45

log() {
    echo "$*" >&2
}

notify() {
    local urgency="$1"
    local message="$2"

    log "NOTIFICATION: $message"
    notify-send --app-name="herdr upgrade" --urgency="$urgency" \
        "herdr upgrade" "$message" 2>/dev/null || true
}

is_herdr_server() {
    local pid="$1"
    local argv=()

    mapfile -d '' -t argv <"/proc/$pid/cmdline" 2>/dev/null || return 1
    [[ ${#argv[@]} -ge 2 && "${argv[0]##*/}" == "herdr" && "${argv[1]}" == "server" ]]
}

# After a live handoff, the server is not the unit's main process.
find_unit_servers() {
    local cgroup pid

    cgroup=$(systemctl --user show "$UNIT" -P ControlGroup)
    [[ -n "$cgroup" && -r "/sys/fs/cgroup$cgroup/cgroup.procs" ]] || return 0

    while read -r pid; do
        if is_herdr_server "$pid"; then
            echo "$pid"
        fi
    done <"/sys/fs/cgroup$cgroup/cgroup.procs"
}

find_unmanaged_servers() {
    local unit_cgroup pid

    unit_cgroup=$(systemctl --user show "$UNIT" -P ControlGroup)

    for pid in $(pgrep -u "$(id -u)" -x herdr || true); do
        if ! is_herdr_server "$pid"; then
            continue
        fi
        if [[ -n "$unit_cgroup" ]] && grep -qxF "0::$unit_cgroup" "/proc/$pid/cgroup" 2>/dev/null; then
            continue
        fi
        echo "$pid"
    done
}

server_answers() {
    "$HERDR_BIN" api snapshot >/dev/null 2>&1
}

all_panes_idle() {
    local snapshot busy_agents pane process_info

    snapshot=$("$HERDR_BIN" api snapshot) || return 1

    busy_agents=$(jq -r '
        .result.snapshot.panes[]
        | select(.agent != null)
        | select(.agent_status | IN("idle", "done") | not)
        | "\(.pane_id) (\(.agent): \(.agent_status))"
    ' <<<"$snapshot") || return 1
    if [[ -n "$busy_agents" ]]; then
        log "Busy agent panes: ${busy_agents//$'\n'/, }"
        return 1
    fi

    for pane in $(jq -r '.result.snapshot.panes[] | select(.agent == null) | .pane_id' <<<"$snapshot"); do
        process_info=$("$HERDR_BIN" pane process-info --pane "$pane") || return 1
        if ! jq -e '.result.process_info | .foreground_process_group_id == .shell_pid' \
            <<<"$process_info" >/dev/null; then
            log "Pane $pane runs a foreground command:" \
                "$(jq -r '[.result.process_info.foreground_processes[].name] | join(", ")' <<<"$process_info")"
            return 1
        fi
    done
}

wait_until_all_panes_idle() {
    until all_panes_idle; do
        log "Waiting $IDLE_POLL_SECONDS seconds for all panes to become idle"
        sleep "$IDLE_POLL_SECONDS"
    done
    log "All panes are idle"
}

wait_for_exit() {
    local pid="$1"
    local seconds_left="$2"

    while kill -0 "$pid" 2>/dev/null; do
        if ((seconds_left == 0)); then
            return 1
        fi
        sleep 1
        ((seconds_left--))
    done
}

start_unit() {
    systemctl --user reset-failed "$UNIT" 2>/dev/null || true
    systemctl --user start "$UNIT"
}

move_unmanaged_server_to_unit() {
    local pid="$1"

    # A live handoff would start the new server in the old server's cgroup,
    # still outside systemd, so restart instead.
    log "herdr server $pid runs outside systemd. Moving it to $UNIT when all panes are idle."
    wait_until_all_panes_idle
    "$HERDR_BIN" server stop
    if ! wait_for_exit "$pid" 30; then
        notify critical "herdr server $pid did not stop. It still runs outside systemd."
        return 1
    fi
    start_unit
    log "Moved the herdr server to $UNIT"
}

hand_off() {
    local old_pid="$1"
    local servers=()

    log "Handing off herdr server $old_pid to $HERDR_BIN"
    if "$HERDR_BIN" server live-handoff --import-exe "$HERDR_BIN"; then
        wait_for_exit "$old_pid" "$HANDOFF_SETTLE_SECONDS" || true
    else
        # The reply can be lost even when the handoff succeeds.
        log "live-handoff reported a failure. Checking the result."
    fi

    mapfile -t servers < <(find_unit_servers)

    if ((${#servers[@]} == 0)); then
        start_unit
        notify critical "Live handoff failed and herdr lost its panes. Started $UNIT again."
        return 1
    fi

    if ! server_answers; then
        notify critical "Live handoff failed. herdr server ${servers[*]} keeps the pane processes running, but does not answer. Restart $UNIT when you are ready."
        return 1
    fi

    if ((${#servers[@]} == 1)) && [[ "$(readlink "/proc/${servers[0]}/exe")" == "$HERDR_BIN" ]]; then
        log "Live handoff complete. herdr server ${servers[0]} runs $HERDR_BIN."
        return 0
    fi

    notify normal "Live handoff failed and herdr rolled back. herdr restarts on the new version when all panes are idle."
    wait_until_all_panes_idle
    systemctl --user restart "$UNIT"
    log "Restarted $UNIT"
}

main() {
    local unit_servers=() unmanaged_servers=() running_binary

    mapfile -t unit_servers < <(find_unit_servers)
    mapfile -t unmanaged_servers < <(find_unmanaged_servers)

    if ((${#unmanaged_servers[@]} > 0)); then
        move_unmanaged_server_to_unit "${unmanaged_servers[0]}"
        return
    fi

    if ((${#unit_servers[@]} == 0)); then
        log "No herdr server is running. Starting $UNIT."
        start_unit
        return
    fi

    if ((${#unit_servers[@]} > 1)); then
        notify critical "$UNIT has more than one herdr server: ${unit_servers[*]}. A handoff may be in progress. Nothing was changed."
        return 1
    fi

    running_binary=$(readlink "/proc/${unit_servers[0]}/exe")
    if [[ "$running_binary" == "$HERDR_BIN" ]]; then
        log "herdr server ${unit_servers[0]} already runs $HERDR_BIN"
        return 0
    fi

    log "herdr server ${unit_servers[0]} runs $running_binary, expected $HERDR_BIN"
    hand_off "${unit_servers[0]}"
}

main "$@"
