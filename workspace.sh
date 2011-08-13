#!/bin/bash

_BWS_DIR=~/.bash-workspace
_BWS_ALIAS="bws"

_bws_args() {
# Pass variables through:
#   <cmd> `eval _bws_args <first_index> "$@"`
# @param Index of first argument to pass through
# @param List of parameters
    local i=1
    local min=$(( $1 + 1 ))
    for var in "$@"; do
        i=$(( $i + 1 ))
        if [ $i -gt $min ]; then echo $var; fi
    done;
}

_bws_init() {
    export _bws_active=default
    mkdir $_BWS_DIR > /dev/null 2>&1
    mkdir $_BWS_DIR/log> /dev/null 2>&1
    _bws_load_workspace
    _bws_remove_empty_workspaces
}

_bws_load_workspace() { 
    source $_BWS_DIR/active 2> /dev/null
    unset ${!_bws_link_*}
    source $_BWS_DIR/log/$_bws_active 2> /dev/null
    if [ $? == 1 ]; then
        if [ $_bws_active == 'default' ]; then
            _bws_add_link r "`echo ~`"
        else
            _bws_add_link r "`pwd`"
        fi
        _bws_save_workspace
    fi
}

_bws_save_workspace() {
    export -p | grep _bws_link_ | sed -e 's/.*\?_bws_link_/export _bws_link_/g' > $_BWS_DIR/log/$_bws_active
}

_bws_export_workspace_to_vim() {
    mkdir $_BWS_DIR/vim 2> /dev/null
    export -p | grep _bws_link_ | sed -e 's/.*\?_bws_link_/let _bws_link_/g' > $_BWS_DIR/vim/$_bws_active
}

_bws_remove_empty_workspaces() {
    for ws in `ls $_BWS_DIR/log`; do
        local file_size=`du -b $_BWS_DIR/log/$ws | sed -e s/[^0-9]*//g`
        if [ $file_size -le 1 ] && [ "$ws" != "default" ] && [ "$ws" != $_bws_active ]; then
            rm "$_BWS_DIR/log/$ws"
        fi;
    done;
}

_bws_change_workspace() {
# @param workspace to be activated
    _bws_save_workspace
    echo "export _bws_active=$1" > $_BWS_DIR/active
    _bws_load_workspace
}

_bws_activate_workspace() {
# @param workspace to be activated
    echo "export _bws_active=$1" > $_BWS_DIR/active
    _bws_load_workspace
}

_bws_empty_workspace() {
    local root="$_bws_link_r"
    unset ${!_bws_link_*}
    export _bws_link_r="$root"
    _bws_save_workspace
}

_bws_remove_workspace() {
    unset ${!_bws_link_*}
    rm $_BWS_DIR/log/$_bws_active
    _bws_activate_workspace "default"
}

_bws_remove_all_workspaces() {
    unset ${!_bws_link_*}
    rm $_BWS_DIR/log/*
    _bws_activate_workspace "default"
    _bws_save_workspace
}

_bws_escape() {
# Replace illegal characters with underline
# @param Link name
    echo $1 | sed -e s/[^a-z0-9_]/_/gi
}

_bws_escape_current_basename() {
    local tmp="`pwd`"
    tmp="`basename "$tmp"`"
    _bws_escape "$tmp"
}

_bws_add_link() {
# @param Link name
# @param Target directory
    export _bws_link_$1="$2"
    _bws_save_workspace
}

_bws_remove_links() {
# @param List of link names
    for var in $@; do
        unset _bws_link_$var
    done;
    _bws_save_workspace
}

_bws_lookup() {
# Get directory path that link poins to
# @param Link name
    local path=_bws_link_$1;
    path=${!path}
    if [ -z "$path" ]; then
        return 1
    fi
    echo $path
}

_bws_list_workspaces() {
    local s="[" #local s="\033[40m\033[1;34m"
    local e="]" #local e="\033[0m"
    for ws in `ls $_BWS_DIR/log`; do
        if [ "$ws" == $_bws_active ]; then
            echo -n -e "${s}$ws${e} "
        else
            echo -n -e "$ws "
        fi;
    done;
    echo
}

_bws_list_link_names() {
# List links in current workspace
    export -p | grep _bws_link_ | sed -e 's/.*\?_bws_link_//g' -e 's/=.*//g' | tr "\n" " "
    echo
}

_bws_list_links() {
# List links in current workspace
    export -p | grep _bws_link_ | sed -e 's/.*\?_bws_link_//g'
}

_bws_confirm() {
# Get user confirmation
# @param message
# @return 0 if user answered yes, 1 otherwise
    message=$1
    echo -n "$message Yes/No "
    read action_confirmed
    local action_confirmed=`echo $action_confirmed | tr '[:upper:]' '[:lower:]'`
    if [ "$action_confirmed" == "yes" ] || [ "$action_confirmed" == "y" ]; then
        return 0
    else
        return 1
    fi
}

_bws_list_commands() {
    echo "cd cw empty help ln lookup ls reset rm"
}

_bws_helptext() {
# @param Name of command
    echo "Usage: $1 [COMMAND]"
    echo "If COMMAND is not specified, current workspaces are listed."
    echo
    echo "Available commands:"
    echo "cd [NAME]             Change directory, if NAME is omitted, go to \"r\" (workspace root)"
    echo "cw [NAME]             Change workspace, if NAME is omitted, default workspace is activated"
    echo "empty                 Empty active workspace (removing all links)"
    echo "help                  Display this.."
    echo "ln NAME [DIRECTORY]   Add link to DIRECTORY, or to current working directory if not specified"
    echo "lookup NAME           Lookup link (returns an absolute filepath)"
    echo "ls                    List all directories in workspace"
    echo "reset                 Remove all workspaces"
    echo "rm [NAME]...          Remove directories from workspace, or remove entire workspace if no names are specified"
}

_bws_autocomplete() {
    local cur suggestions cmd
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    cmd="${COMP_WORDS[1]}"

    if [ $COMP_CWORD -eq 1 ]; then
        suggestions="`_bws_list_commands`"
    elif [ $COMP_CWORD -eq 2 ]; then
        if [ "$cmd" == "cd" ] || [ "$cmd" == "rm" ] || [ "$cmd" == "lookup" ]; then
            suggestions="`_bws_list_link_names`"
        elif [ "$cmd" == "cw" ]; then
            suggestions="`ls $_BWS_DIR/log` `_bws_escape_current_basename`"
        elif [ "$cmd" == "ln" ]; then
            suggestions="`_bws_escape_current_basename`"
        fi
    elif [ $COMP_CWORD -eq 3 ]; then
        if [ "$cmd" == "ln" ] ; then
            suggestions="`ls`"
        fi
    fi
    COMPREPLY=(`compgen -W "${suggestions}" $cur`)
}

_bws_run() {
    _bws_init

    local command="$1"

    # Add
    if [ "$command" == 'ln' ]; then
        if [ -n "$2" ]; then
            local dir=`pwd`
            if [ -n "$3" ]; then dir="$3"; fi
            _bws_add_link `_bws_escape "$2"` $dir
        else
            _bws_helptext $_BWS_ALIAS
        fi

    # Remove
    elif [ "$command" == 'rm' ]; then
        if [ -n "$2" ]; then
            _bws_remove_links `eval _bws_args 2 "$@"`
        else
            _bws_confirm "Remove active workspace ($_bws_active)?" && _bws_remove_workspace
        fi

    # Lookup
    elif [ "$command" == 'lookup' ]; then
        echo `_bws_lookup "$2"`

    # Change directory
    elif [ "$command" == 'cd' ]; then
        if [ -n "$2" ]; then
            cd "`_bws_lookup $2`"
        else
            cd "`_bws_lookup r`"
        fi

    # Change workspace
    elif [ "$command" == 'cw' ]; then
        if [ -n "$2" ]; then
            _bws_change_workspace `_bws_escape "$2"`
        else
            _bws_change_workspace default
        fi

    # Reset (remove all workspaces)
    elif [ "$command" == 'reset' ]; then
        _bws_confirm "Remove all workspaces?" && _bws_remove_all_workspaces && _bws_activate_workspace "default"

    # Empty workspace
    elif [ "$command" == 'empty' ]; then
        _bws_confirm "Empty workspace ($_bws_active)?" && _bws_empty_workspace

    # List links
    elif [ "$command" == 'ls' ]; then
        _bws_list_links

    # Help
    elif [ "$command" == 'help' ]; then
        _bws_helptext $_BWS_ALIAS

    # List workspaces
    elif [ -z "$command" ]; then
        _bws_list_workspaces

    # Autocomplete
    elif [ "$command" == 'autocomplete' ]; then
        if [ -n "$2" ]; then 
            complete -F _bws_autocomplete "$2"
        else
            complete -F _bws_autocomplete $_BWS_ALIAS
        fi;

    # Run workspace function directly
    elif [ "$command" == '_call' ]; then
        eval "_bws_$2 `eval _bws_args 3 "$@"`"

    # Default
    else
        _bws_helptext $_BWS_ALIAS
    fi
}

_bws_run "$@"
