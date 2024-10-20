# ex: filetype=sh
# shellcheck disable=SC2207
_pt_completions()
{
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=($(compgen -W '-debug -c -config -help' -- "$cur"))
    case "$prev" in
        -c|-config)
            COMPREPLY+=($(compgen -f -- "$cur"))
            ;;
        -l|-label)
            if [[ ${COMP_WORDS[*]} =~ start ]]; then
                COMPREPLY+=($(compgen -W "$(pt labels)" -- "$cur"))
            fi
            ;;
        *)
            local words=($(pt ls -o brief) start stop signal)
            if [[ ${words[*]} =~ $prev ]]; then
                COMPREPLY+=($(compgen -W "$(pt ls -o brief)" -- "$cur"))
            fi
            local commands='start stop ls ps help version signal labels'
            local invoked=()
            for comm in $commands; do
                if [[ ${COMP_WORDS[*]} =~ $comm ]]; then
                    invoked+=("$comm")
                fi
            done
            # Do not complete commands if any command is already invoked
            if [[ "${#invoked[@]}" == 0 ]]; then
                COMPREPLY+=($(compgen -W "$commands" -- "$cur"))
            fi
            ;;
    esac
}

complete -o filenames -F _pt_completions pt
