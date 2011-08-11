#!/bin/bash

#
# Author Stian Liknes <stianlik@gmail.com>
# Created: 2011-08-10
#

export _bws_dir=~/.bash-workspace

_bws_args() {
# Pass variables through:
#   <cmd> `eval _bws_args <first_index> "$@"`
# @param Index of first argument to pass through
# @param Numer of first argument
    local i=0
    local min=$(( $1 + 1 ))
    for var in "$@"; do
        i=$(( $i + 1 ))
        if [ $i -gt $min ]; then echo $var; fi
    done;
}

_bws_init() {
    export _bws_active=default
    mkdir $_bws_dir > /dev/null 2>&1
    mkdir $_bws_dir/log> /dev/null 2>&1
    _bws_load
    _bws_remove_empty
}

_bws_load() { 
# Load workspace from persistent storage
    source $_bws_dir/active 2> /dev/null
    unset ${!_bws_link_*}
    source $_bws_dir/log/$_bws_active 2> /dev/null
    if [ $? == 1 ]; then
        if [ $_bws_active == 'default' ]; then
            _bws_add_link r "`echo ~`"
        else
            _bws_add_link r "`pwd`"
        fi
        _bws_save
    fi
}

_bws_save() {
# Save workspace to persistent storage
    export -p | grep _bws_link_ | sed -e 's/.*\?_bws_link_/export _bws_link_/g' > $_bws_dir/log/$_bws_active
}

_bws_remove_empty() {
# Remove empty workspaces except default and active
    for ws in `ls $_bws_dir/log`; do
        local file_size=`du -b $_bws_dir/log/$ws | sed -e s/[^0-9]*//g`
        if [ $file_size -le 1 ] && [ "$ws" != "default" ] && [ "$ws" != $_bws_active ]; then
            rm "$_bws_dir/log/$ws"
        fi;
    done;
}

_bws_change() {
# Change workspace
# @param workspace
    _bws_save
    echo "export _bws_active=$1" > $_bws_dir/active
    _bws_load
}

_bws_activate() {
# Activate workspace
# @param workspace
    echo "export _bws_active=$1" > $_bws_dir/active
    _bws_load
}

_bws_empty_active() {
# Empty the current workspace
    local root="$_bws_link_r"
    unset ${!_bws_link_*}
    export _bws_link_r="$root"
    _bws_save
}

_bws_remove() {
# Remove workspace
    unset ${!_bws_link_*}
    rm $_bws_dir/log/$_bws_active
    _bws_activate "default"
}

_bws_remove_all() {
# Remove all workspaces
    unset ${!_bws_link_*}
    rm $_bws_dir/log/*
    _bws_activate "default"
    _bws_save
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
# Add link to active workspace
# @param Link name
# @param Target directory
    _bws_cmd="export _bws_link_$1='$2'"
    eval $_bws_cmd
    _bws_save
}

_bws_remove_links() {
# Remove link from active workspace
# @param Link names
    for var in $@; do
        unset _bws_link_$var
    done;
    _bws_save
}

_bws_change_directory() {
# @param Link name
    local _bws_path=_bws_link_$1;
    _bws_path=${!_bws_path}
    if [ -n "$_bws_path" ]; then
        cd $_bws_path
        return 0
    fi
    return 1
}

_bws_list() {
# List workspaces
    local s="[" #local s="\033[40m\033[1;34m"
    local e="]" #local e="\033[0m"
    for ws in `ls $_bws_dir/log`; do
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
    echo -n "$message (Yes/No)? "
    read action_confirmed
    local action_confirmed=`echo $action_confirmed | tr '[:upper:]' '[:lower:]'`
    if [ "$action_confirmed" == "yes" ] || [ "$action_confirmed" == "y" ]; then
        return 0
    else
        return 1
    fi
}

_bws_remove_confirm() {
    _bws_confirm "Remove active workspace ($_bws_active)"
    if [ $? == 1 ]; then
        echo "Nothing done"
        return
    fi
    _bws_remove
}

_bws_remove_all_confirm() {
    _bws_confirm "Remove all workspaces"
    if [ $? == 1 ]; then
        echo "Nothing done"
        return
    fi
    _bws_remove_all
    _bws_activate "default"
}

_bws_change_directory_confirm() {
# @param Link name
    _bws_change_directory $1
    if [ $? == 1 ]; then
        echo "Could not find link ('$1')"
    fi
}

_bws_empty_active_confirm() { 
# Empty the active workspace (removing all links)
    _bws_confirm "Empty workspace ($_bws_active)"
    if [ $? == 1 ]; then
        echo "Nothing done"
        return
    fi
    _bws_empty_active
}

_bws_list_commands() {
    echo "cd cw empty help ln ls reset rm"
}

_bws_helptext() {
# @param Name of command
    echo "Assuming $1 is an alias for \"source /path/to/workspace.sh\""
    echo "Usage: $1                       List workspaces"
    echo "   or: $1 cd [<name>]           Change directory, if <name> is omitted, go to \"r\" (workspace root)"
    echo "   or: $1 cw [<name>]           Change workspace, if <name> is omitted, default workspace is activated"
    echo "   or: $1 empty                 Empty active workspace (removing all links)"
    echo "   or: $1 help                  Display this.."
    echo "   or: $1 ln <name>             Add link to current directory in active workspace"
    echo "   or: $1 ls                    List all directories in workspace"
    echo "   or: $1 reset                 Remove all workspaces"
    echo "   or: $1 rm [<list of names>]  Remove directories from workspace, or remove entire workspace if <list of names> is omitted"
}

_bws_autocomplete() {
    local cur prev suggestions
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [ $COMP_CWORD -eq 1 ]; then
        suggestions="`_bws_list_commands`"
    elif [ $COMP_CWORD -eq 2 ]; then
        if [ "$prev" == "cd" ] || [ "$prev" == "rm" ]; then
            suggestions="`_bws_list_link_names`"
        elif [ "$prev" == "cw" ]; then
            suggestions="`ls $_bws_dir/log` `_bws_escape_current_basename`"
        elif [ "$prev" == "ln" ]; then
            suggestions="`_bws_escape_current_basename`"
        fi
    fi
    COMPREPLY=(`compgen -W "${suggestions}" $cur`)
}

_bws_run() {
# @param command
# @param name
    _bws_init

    local me="bws"
    local _bws_command="$1"
    local _bws_name="$2"

    # Add
    if [ "$_bws_command" == 'ln' ]; then
        if [ -n "$_bws_name" ]; then
            _bws_add_link `_bws_escape "$_bws_name"` "`pwd`"
        else
            _bws_helptext $me
        fi

    # Remove
    elif [ "$_bws_command" == 'rm' ]; then
        if [ -n "$_bws_name" ]; then
            _bws_remove_links `eval _bws_args 1 "$@"`
        else
            _bws_remove_confirm
        fi

    # Change directory
    elif [ "$_bws_command" == 'cd' ]; then
        if [ -n "$_bws_name" ]; then
            _bws_change_directory_confirm `_bws_escape "$_bws_name"`
        else
            _bws_change_directory_confirm r # Workspace root dir
        fi

    # Change workspace
    elif [ "$_bws_command" == 'cw' ]; then
        if [ -n "$_bws_name" ]; then
            _bws_change `_bws_escape "$_bws_name"`
        else
            _bws_change default
        fi

    # Reset (remove all workspaces)
    elif [ "$_bws_command" == 'reset' ]; then
        _bws_remove_all_confirm `_bws_escape "$_bws_name"`

    # Empty workspace
    elif [ "$_bws_command" == 'empty' ]; then
        _bws_empty_active_confirm

    # List links
    elif [ "$_bws_command" == 'ls' ]; then
        _bws_list_links

    # Help
    elif [ "$_bws_command" == 'help' ]; then
        _bws_helptext $me

    # List workspaces
    elif [ -z "$_bws_command" ]; then
        _bws_list

    # Autocomplete
    elif [ "$_bws_command" == 'autocomplete' ]; then
        if [ -z "$_bws_name" ]; then _bws_name=$me; fi;
        complete -F _bws_autocomplete "$_bws_name"

    # Run workspace function directly
    elif [ "$_bws_command" == '_func' ]; then
        local func=`_bws_escape "$_bws_name"`
        _bws_`eval echo $func`

    # Default
    else
        _bws_helptext $me
    fi
}

_bws_run "$@"
