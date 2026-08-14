#!/usr/bin/env bash
# agent-dashboard-data.sh — aggregate cadence agent state into JSON for the
# agent-dashboard TUI.
#
# Output: JSON array to stdout.  Statuses: WORKING, WAITING_FOR_INPUT, COMPLETED.
#
# Data sources:
#   1. cadence agent list --output json         (running agents)
#   2. cadence agent state get <slug> --json    (phase enrichment)
#   3. cadence agent completed --output json    (completed, pending review)
#   4. box-picker --list                        (box / remote cross-ref)

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────

# Pull a field from a JSON object on stdin (single-line object).
_json_field() { jq -r ".${1} // empty" 2>/dev/null; }

# Run a cadence command with a timeout (backend may be unreachable).
_cadence() { timeout 10 cadence "$@" 2>/dev/null || true; }

# Resolve project path from project slug.  We look in known project roots.
resolve_project_path() {
    local slug="$1"
    for root in /mnt/data/personal /mnt/data/work /home/notpc/projects; do
        local cand="${root}/${slug}"
        if [[ -d "${cand}" ]]; then
            echo "${cand}"
            return 0
        fi
    done
    # Not found — leave empty.
    echo ""
}

# ── Box cross-reference cache ─────────────────────────────────────────────

declare -A BOX_LOOKUP  # project_slug → "box_name<TAB>is_remote"

_load_box_cache() {
    BOX_LOOKUP=()
    local list
    list=$(timeout 5 box-picker --list 2>/dev/null || true)
    [[ -z "${list}" ]] && return 0

    while IFS=$'\t' read -r display box_name wt_path ip tmux_s browser_s; do
        [[ -z "${box_name}" ]] && continue
        # display is like "personal/dotfiles" — extract the top-level project slug.
        local proj_slug="${display%%/*}"
        local is_remote="false"
        [[ "${ip}" != "--" && "${ip}" != "host" ]] && is_remote="true"
        BOX_LOOKUP["${proj_slug}"]="${box_name}"$'\t'"${is_remote}"
    done <<< "${list}"
}

# ── Phase → status mapping ────────────────────────────────────────────────

# Cadence agent phases that mean "waiting for human input".
is_waiting_phase() {
    case "${1:-}" in
        WAITING_FOR_INPUT|REVIEWING) return 0 ;;
        *) return 1 ;;
    esac
}

# Cadence agent phases that mean "finished / terminal".
is_terminal_phase() {
    case "${1:-}" in
        COMPLETED|FAILED|MERGED|REJECTED) return 0 ;;
        *) return 1 ;;
    esac
}

# ── Main aggregation ──────────────────────────────────────────────────────

main() {
    _load_box_cache

    declare -A seen  # dedup by taskSlug

    # Temporary array for results (JSON objects, one per line).
    local tmpfile
    tmpfile=$(mktemp /tmp/agent-dashboard-data.XXXXXX)
    : > "${tmpfile}"

    # ── 1. Running agents from cadence ──────────────────────────────────
    local agents_json
    agents_json=$(_cadence agent list --output json || echo "[]")

    # Also grab agent runs for richer status/phase data.
    local runs_json
    runs_json=$(_cadence agent run list --output json || echo "[]")

    # Iterate each agent from the list.
    echo "${agents_json}" | jq -c '.[]' 2>/dev/null | while IFS= read -r agent; do
        [[ -z "${agent}" ]] && continue

        local task_slug task_title proj_slug tmux_session pid
        task_slug=$(echo "${agent}" | _json_field "taskSlug")
        task_title=$(echo "${agent}" | _json_field "taskTitle")
        proj_slug=$(echo "${agent}" | _json_field "projectSlug")
        tmux_session=$(echo "${agent}" | _json_field "tmuxSession")
        pid=$(echo "${agent}" | _json_field "pid")

        [[ -z "${task_slug}" ]] && continue

        seen["${task_slug}"]=1

        # Enrich with agent state (phase).
        local phase="" status="WORKING" needs_input="false"
        local state_json
        state_json=$(_cadence agent state get "${task_slug}" --output json || echo "{}")
        phase=$(echo "${state_json}" | _json_field "phase")
        [[ -z "${phase}" ]] && phase=$(echo "${state_json}" | _json_field "status")

        # Determine display status.
        if is_waiting_phase "${phase}"; then
            status="WAITING_FOR_INPUT"
            needs_input="true"
        elif is_terminal_phase "${phase}"; then
            status="COMPLETED"
        fi

        # Start time / runtime calculation.
        local started_at="" runtime=""
        started_at=$(echo "${agent}" | _json_field "startedAt")
        started_at="${started_at:-$(echo "${state_json}" | _json_field "createdAt")}"
        if [[ -n "${started_at}" ]]; then
            local started_epoch now_epoch
            started_epoch=$(date -d "${started_at}" +%s 2>/dev/null || echo 0)
            now_epoch=$(date +%s)
            if [[ "${started_epoch}" -gt 0 ]]; then
                local diff=$(( now_epoch - started_epoch ))
                if [[ $diff -lt 60 ]]; then
                    runtime="${diff}s"
                elif [[ $diff -lt 3600 ]]; then
                    runtime="$(( diff / 60 ))m"
                else
                    runtime="$(( diff / 3600 ))h $(( (diff % 3600) / 60 ))m"
                fi
            fi
        fi

        # Worktree info from agent state.
        local worktree=""
        worktree=$(echo "${state_json}" | _json_field "worktree")

        # Project path.
        local proj_path
        proj_path=$(resolve_project_path "${proj_slug}")

        # Box cross-reference.
        local box_name="" is_remote="false"
        if [[ -n "${BOX_LOOKUP[${proj_slug}]:-}" ]]; then
            IFS=$'\t' read -r box_name is_remote <<< "${BOX_LOOKUP[${proj_slug}]}"
        fi

        # Emit JSON object.
        jq -n \
            --arg taskSlug "${task_slug}" \
            --arg taskTitle "${task_title}" \
            --arg projectSlug "${proj_slug}" \
            --arg projectPath "${proj_path:-~}" \
            --arg status "${status}" \
            --arg phase "${phase:-RUNNING}" \
            --arg runtime "${runtime:-}" \
            --arg tmuxSession "${tmux_session:-}" \
            --arg pid "${pid:-}" \
            --arg needsInput "${needs_input}" \
            --arg worktree "${worktree:-}" \
            --arg boxName "${box_name:-}" \
            --arg isRemote "${is_remote}" \
            --arg source "cadence" \
            '{
                taskSlug: $taskSlug,
                taskTitle: $taskTitle,
                projectSlug: $projectSlug,
                projectPath: $projectPath,
                status: $status,
                phase: $phase,
                runtime: $runtime,
                tmuxSession: $tmuxSession,
                pid: $pid,
                needsInput: $needsInput,
                worktree: $worktree,
                boxName: $boxName,
                isRemote: $isRemote,
                source: $source
            }' >> "${tmpfile}"
    done

    # ── 2. Completed agents pending review ──────────────────────────────
    local completed_json
    completed_json=$(_cadence agent completed --output json || echo "[]")

    echo "${completed_json}" | jq -c '.[]' 2>/dev/null | while IFS= read -r entry; do
        [[ -z "${entry}" ]] && continue

        local task_slug
        task_slug=$(echo "${entry}" | _json_field "taskSlug")
        [[ -z "${task_slug}" ]] && continue

        # Skip if we already have it (shouldn't happen, but dedup).
        [[ -n "${seen[${task_slug}]:-}" ]] && continue
        seen["${task_slug}"]=1

        local task_title proj_slug worktree runtime
        task_title=$(echo "${entry}" | _json_field "taskTitle")
        proj_slug=$(echo "${entry}" | _json_field "projectSlug")
        worktree=$(echo "${entry}" | _json_field "worktree")
        runtime=$(echo "${entry}" | _json_field "duration")

        local proj_path
        proj_path=$(resolve_project_path "${proj_slug}")

        local box_name="" is_remote="false"
        if [[ -n "${BOX_LOOKUP[${proj_slug}]:-}" ]]; then
            IFS=$'\t' read -r box_name is_remote <<< "${BOX_LOOKUP[${proj_slug}]}"
        fi

        jq -n \
            --arg taskSlug "${task_slug}" \
            --arg taskTitle "${task_title}" \
            --arg projectSlug "${proj_slug}" \
            --arg projectPath "${proj_path:-~}" \
            --arg status "COMPLETED" \
            --arg phase "PENDING_REVIEW" \
            --arg runtime "${runtime:-}" \
            --arg worktree "${worktree:-}" \
            --arg boxName "${box_name:-}" \
            --arg isRemote "${is_remote}" \
            --arg source "cadence" \
            '{
                taskSlug: $taskSlug,
                taskTitle: $taskTitle,
                projectSlug: $projectSlug,
                projectPath: $projectPath,
                status: $status,
                phase: $phase,
                runtime: $runtime,
                tmuxSession: "",
                pid: "",
                needsInput: "false",
                worktree: $worktree,
                boxName: $boxName,
                isRemote: $isRemote,
                source: $source
            }' >> "${tmpfile}"
    done

    # ── 3. Merge and output ────────────────────────────────────────────
    if [[ -s "${tmpfile}" ]]; then
        # Collect all JSON objects into an array, sort by status priority
        # (WAITING_FOR_INPUT first, then WORKING, then COMPLETED).
        jq -s 'sort_by(
            if .status == "WAITING_FOR_INPUT" then 0
            elif .status == "WORKING" then 1
            else 2 end
        )' "${tmpfile}"
    else
        echo "[]"
    fi

    rm -f "${tmpfile}"
}

main "$@"
