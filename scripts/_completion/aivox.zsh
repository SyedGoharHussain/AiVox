#compdef aivox aivox-backup aivox-calendar aivox-contacts aivox-cookbook aivox-docs aivox-gallery aivox-mail aivox-mcp aivox-memory aivox-notes aivox-personal aivox-preset aivox-research aivox-sessions aivox-signature aivox-skills aivox-tasks aivox-theme aivox-webhook
# Zsh tab-completion for the aivox umbrella + sub-CLIs.
#
# Drop in any directory on $fpath, e.g.:
#     fpath=(/path/to/aivox-ui/scripts/_completion $fpath)
#     autoload -U compinit; compinit
#
# Then `aivox <tab>` completes subcommands; `aivox mail <tab>`
# completes mail subcommands; `aivox-mail <tab>` works the same.

_aivox_scripts_dir() {
    local self="${(%):-%x}"
    while [[ -L "$self" ]]; do self="$(readlink "$self")"; done
    cd "${self:h}/.." && pwd
}

typeset -gA _aivox_subs

_aivox_refresh() {
    _aivox_subs=()
    local dir="$(_aivox_scripts_dir)"
    local py="$dir/../venv/bin/python"
    [[ -x "$py" ]] || py="$(command -v python3)"
    local f sub help_out commands
    for f in "$dir"/aivox-*; do
        [[ -x "$f" ]] || continue
        case "$f" in
            *.bak|*.pyc|*.pre-*) continue ;;
        esac
        sub="${${f:t}#aivox-}"
        help_out=$("$py" "$f" --help 2>/dev/null) || continue
        commands=$(echo "$help_out" | grep -oE '\{[a-z0-9_,-]+\}' | head -1 \
            | tr -d '{}' | tr ',' ' ')
        _aivox_subs[$sub]="$commands"
    done
}

_aivox() {
    [[ ${#_aivox_subs} -eq 0 ]] && _aivox_refresh

    local cmd="${words[1]}"

    if [[ "$cmd" == "aivox" ]]; then
        if (( CURRENT == 2 )); then
            local -a subs=(${(k)_aivox_subs} help)
            _describe 'subcommand' subs
            return
        fi
        local sub="${words[2]}"
        if [[ "$sub" == "help" ]] && (( CURRENT == 3 )); then
            local -a subs=(${(k)_aivox_subs})
            _describe 'subcommand' subs
            return
        fi
        if (( CURRENT == 3 )); then
            local -a sc=(${(s/ /)_aivox_subs[$sub]})
            _describe 'command' sc
            return
        fi
        return
    fi

    # aivox-foo <tab>
    local sub="${cmd#aivox-}"
    if (( CURRENT == 2 )); then
        local -a sc=(${(s/ /)_aivox_subs[$sub]})
        _describe 'command' sc
        return
    fi
}

_aivox "$@"
