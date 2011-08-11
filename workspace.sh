#!/bin/bash

#
# Author Stian Liknes <stianlik@gmail.com>
# Created: 2011-08-10
#

export workspace_dir=~/.bash-workspace

workspace_init() {
    export workspace_active=default
    mkdir $workspace_dir > /dev/null 2>&1
    mkdir $workspace_dir/log> /dev/null 2>&1
    workspace_load
    workspace_remove_empty
}

workspace_load() { 
# Load workspace from persistent storage
    source $workspace_dir/active 2> /dev/null
    unset ${!workspace_link_*}
    source $workspace_dir/log/$workspace_active 2> /dev/null
    if [ $? == 1 ]; then
        workspace_add_link r "`pwd`"
        workspace_save
    fi
}

workspace_save() {
# Save workspace to persistent storage
    echo `export -p | grep workspace_link_ | sed -e 's/.*\?workspace_link_/export workspace_link_/g'`>$workspace_dir/log/$workspace_active
}

workspace_remove_empty() {
# Remove empty workspaces except default and active
    for ws in `ls $workspace_dir/log`; do
        local file_size=`du -b $workspace_dir/log/$ws | sed -e s/[^0-9]*//g`
        if [ $file_size -le 1 ] && [ "$ws" != "default" ] && [ "$ws" != $workspace_active ]; then
            rm "$workspace_dir/log/$ws"
        fi;
    done;
}

workspace_change() {
# Change workspace
# @param workspace
    workspace_save
    echo "export workspace_active=$1" > $workspace_dir/active
    workspace_load
}

workspace_activate() {
# Activate workspace
# @param workspace
    echo "export workspace_active=$1" > $workspace_dir/active
    workspace_load
}

workspace_empty_active() {
# Empty the current workspace
    unset ${!workspace_link_*}
    workspace_save
}

workspace_remove() {
# Remove workspace
    unset ${!workspace_link_*}
    rm $workspace_dir/log/$workspace_active
    workspace_activate "default"
}

workspace_remove_all() {
# Remove all workspaces
    unset ${!workspace_link_*}
    rm $workspace_dir/log/*
    workspace_activate "default"
    workspace_save
}

workspace_escape() {
# Replace illegal characters with underline
# @param Link name
    echo $1 | sed -e s/[^a-z0-9_]/_/gi
}

workspace_escape_current_basename() {
    local tmp="`pwd`"
    tmp="`basename "$tmp"`"
    workspace_escape "$tmp"
}

workspace_add_link() {
# Add link to active workspace
# @param Link name
# @param Target directory
    workspace_cmd="export workspace_link_$1='$2'"
    eval $workspace_cmd
    workspace_save
}

workspace_remove_link() {
# Remove link from active workspace
# @param Link name
    local workspace_cmd="unset workspace_link_$1"
    eval $workspace_cmd
    workspace_save
}

workspace_change_directory() {
# @param Link name
    local workspace_path=workspace_link_$1;
    local workspace_path=${!workspace_path}
    if [ -n "$workspace_path" ]; then
        cd $workspace_path
        return 0
    fi
    return 1
}

workspace_list() {
# List workspaces
    local s="[" #local s="\033[40m\033[1;34m"
    local e="]" #local e="\033[0m"
    for ws in `ls $workspace_dir/log`; do
        if [ "$ws" == $workspace_active ]; then
            echo -n -e "${s}$ws${e} "
        else
            echo -n -e "$ws "
        fi;
    done;
    echo
}

workspace_list_link_names() {
# List links in current workspace
    export -p | grep workspace_link_ | sed -e 's/.*\?workspace_link_//g' -e 's/=.*//g' | tr "\n" " "
    echo
}

workspace_list_links() {
# List links in current workspace
    export -p | grep workspace_link_ | sed -e 's/.*\?workspace_link_//g'
}

workspace_confirm() {
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

workspace_remove_confirm() {
    workspace_confirm "Remove active workspace ($workspace_active)"
    if [ $? == 1 ]; then
        echo "Nothing done"
        return
    fi
    workspace_remove
}

workspace_remove_all_confirm() {
    workspace_confirm "Remove all workspaces"
    if [ $? == 1 ]; then
        echo "Nothing done"
        return
    fi
    workspace_remove_all
    workspace_activate "default"
}

workspace_change_directory_confirm() {
# @param Link name
    workspace_change_directory $1
    if [ $? == 1 ]; then
        echo "Could not find link ('$1')"
    fi
}

workspace_empty_active_confirm() { 
# Empty the active workspace (removing all links)
    workspace_confirm "Empty workspace ($workspace_active)"
    if [ $? == 1 ]; then
        echo "Nothing done"
        return
    fi
    workspace_empty_active
}

workspace_list_commands() {
    echo "cd cw empty help ln ls reset rm"
}

workspace_helptext() {
    echo "Assuming w is an alias for \"source /path/to/workspace.sh\""
    echo "Usage: w                       List workspaces"
    echo "   or: w cd [<name>]           Change directory, if <name> is omitted, go to \"r\" (workspace root)"
    echo "   or: w cw [<workspace_name>] Change workspace, if <workspace_name> is omitted, default workspace is activated"
    echo "   or: w empty                 Empty active workspace (removing all links)"
    echo "   or: w help                  Display this.."
    echo "   or: w ln <name>             Add link to current directory in active workspace"
    echo "   or: w ls                    List all directories in workspace"
    echo "   or: w reset                 Remove all workspaces"
    echo "   or: w rm [<name>]           Remove directory from workspace, or remove entire workspace if <name> is omitted"
    echo "   or: w start                 Activate workspaces"
}

workspace_autocomplete() {
    local cur prev suggestions
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [ $COMP_CWORD -eq 1 ]; then
        suggestions="`w _func list_commands`"
    elif [ $COMP_CWORD -eq 2 ]; then
        if [ "$prev" == "cd" ] || [ "$prev" == "rm" ]; then
            suggestions="`w _func list_link_names`"
        elif [ "$prev" == "cw" ]; then
            suggestions="`ls $workspace_dir/log` `w _func escape_current_basename`"
        elif [ "$prev" == "ln" ]; then
            suggestions="`w _func escape_current_basename`"
        fi
    fi
    COMPREPLY=(`compgen -W "${suggestions}" $cur`)
}

workspace_run() {
# @param command
# @param name
    workspace_init

    local workspace_command="$1"
    local workspace_name="$2"

    # Add
    if [ "$workspace_command" == 'ln' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_add_link `workspace_escape "$workspace_name"` "`pwd`"
        else
            workspace_helptext
        fi

    # Remove
    elif [ "$workspace_command" == 'rm' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_remove_link `workspace_escape "$workspace_name"`
        else
            workspace_remove_confirm
        fi

    # Change directory
    elif [ "$workspace_command" == 'cd' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_change_directory_confirm `workspace_escape "$workspace_name"`
        else
            workspace_change_directory_confirm r # Workspace root dir
        fi

    # Change workspace
    elif [ "$workspace_command" == 'cw' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_change `workspace_escape "$workspace_name"`
        else
            workspace_change default
        fi

    # Reset (remove all workspaces)
    elif [ "$workspace_command" == 'reset' ]; then
        workspace_remove_all_confirm `workspace_escape "$workspace_name"`

    # Empty workspace
    elif [ "$workspace_command" == 'empty' ]; then
        workspace_empty_active_confirm

    # List links
    elif [ "$workspace_command" == 'ls' ]; then
        workspace_list_links

    # Help
    elif [ "$workspace_command" == 'help' ]; then
        workspace_helptext

    # List workspaces
    elif [ -z "$workspace_command" ]; then
        workspace_list

    elif [ "$workspace_command" == 'autocomplete' ]; then
        if [ -z "$workspace_name" ]; then workspace_name=w; fi;
        complete -F workspace_autocomplete "`workspace_escape $workspace_name`"

    elif [ "$workspace_command" == '_func' ]; then
        local func=`workspace_escape "$workspace_name"`
        workspace_`eval echo $func`

    # Default
    else
        workspace_helptext
    fi
}

workspace_run "$1" "$2"
