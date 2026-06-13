#!/usr/bin/env bash
# Tab-completion for the `aivox` umbrella + every `aivox-*` CLI.
#
# Source from your shell rc:
#     source /path/to/aivox-ui/scripts/_completion/aivox.bash
#
# Or wire it once per machine:
#     sudo install -m 644 aivox.bash /etc/bash_completion.d/aivox
#
# What it does:
#   - On the first word after `aivox`, complete with the list of
#     subcommands (`mail`, `calendar`, ...).
#   - On subsequent words, complete with the subcommand's first-token
#     subcommands (`list`, `show`, ...) which we cache by parsing the
#     tool's own --help output. Updates lazily; refresh by running
#     `_aivox_refresh_cache`.
#   - Same completion works for the individual `aivox-foo` scripts.

_aivox_scripts_dir() {
    # Resolve the scripts/ dir from the script that sources us. We assume
    # the user sourced the file directly out of scripts/_completion/.
    local self="${BASH_SOURCE[0]}"
    while [ -L "$self" ]; do self=$(readlink "$self"); done
    cd "$(dirname "$self")/.." && pwd
}

declare -A _AIVOX_SUBS_CACHE=()

_aivox_refresh_cache() {
    local dir="$(_aivox_scripts_dir)"
    _AIVOX_SUBS_CACHE=()
    # Prefer the project venv's Python so deps (bcrypt, sqlalchemy, ...)
    # resolve. Falls back to system `python3` for container installs.
    local py="$dir/../venv/bin/python"
    [ -x "$py" ] || py="$(command -v python3)"
    local f
    for f in "$dir"/aivox-*; do
        [ -x "$f" ] || continue
        case "$f" in *.bak|*.pyc|*.pre-*) continue ;; esac
        local name="$(basename "$f")"
        local sub="${name#aivox-}"
        local help_out
        help_out=$("$py" "$f" --help 2>/dev/null) || continue
        local commands
        commands=$(echo "$help_out" | grep -oE '\{[a-z0-9_,-]+\}' | head -1 \
            | tr -d '{}' | tr ',' ' ')
        _AIVOX_SUBS_CACHE[$sub]="$commands"
    done
}

_aivox_complete() {
    [ ${#_AIVOX_SUBS_CACHE[@]} -eq 0 ] && _aivox_refresh_cache

    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[0]}"

    # `aivox <tab>` → list every subcommand
    if [ "$cmd" = "aivox" ]; then
        if [ "$COMP_CWORD" -eq 1 ]; then
            local subs="${!_AIVOX_SUBS_CACHE[@]} help"
            COMPREPLY=($(compgen -W "$subs" -- "$cur"))
            return 0
        fi
        # `aivox foo <tab>` — complete with foo's own subcommands
        local sub="${COMP_WORDS[1]}"
        # `aivox help <tab>` lists every subcommand
        if [ "$sub" = "help" ] && [ "$COMP_CWORD" -eq 2 ]; then
            COMPREPLY=($(compgen -W "${!_AIVOX_SUBS_CACHE[*]}" -- "$cur"))
            return 0
        fi
        if [ "$COMP_CWORD" -eq 2 ]; then
            COMPREPLY=($(compgen -W "${_AIVOX_SUBS_CACHE[$sub]}" -- "$cur"))
            return 0
        fi
        return 0
    fi

    # Direct `aivox-foo <tab>` (no umbrella)
    local sub="${cmd#aivox-}"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "${_AIVOX_SUBS_CACHE[$sub]}" -- "$cur"))
        return 0
    fi
}

# Register the completion for every aivox-* script + the umbrella.
complete -F _aivox_complete aivox
for f in "$(_aivox_scripts_dir)"/aivox-*; do
    [ -x "$f" ] || continue
    case "$f" in *.bak|*.pyc|*.pre-*) continue ;; esac
    complete -F _aivox_complete "$(basename "$f")"
done
