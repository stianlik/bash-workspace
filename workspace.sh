#!/bin/bash
#
# Author Stian Liknes <stianlik@gmail.com>
# Created: 2011-08-10
#

workspace_dir=~/.bash-workspace

mkdir $workspace_dir > /dev/null 2>&1
mkdir $workspace_dir/log> /dev/null 2>&1

workspace_command=$1
workspace_name=$2

source $workspace_dir/current 2> /dev/null
if [ -z "$workspace_log" ]; then
    workspace_log=default
fi;

workspace_load() { 
# Load workspace from persistent storage
    unset ${!workspace_link_*}
    source $workspace_dir/log/$workspace_log 2> /dev/null
    if [ $? == 1 ]; then
        workspace_save
    fi
}

workspace_save() {
# Save workspace to persistent storage
    echo `export -p | grep workspace_link_ | sed -e 's/.*\?workspace_link_/export workspace_link_/g'` > $workspace_dir/log/$workspace_log
}

workspace_change() {
# Change workspace
# @param workspace
    workspace_save
    export workspace_log=$1
    workspace_load
    echo "export workspace_log=$workspace_log" > $workspace_dir/current
}

workspace_activate() {
# Activate workspace
# @param workspace
    export workspace_log=$1
    workspace_load
    echo "export workspace_log=$workspace_log" > $workspace_dir/current
}

workspace_empty_current() {
# Empty the current workspace
    unset ${!workspace_link_*}
    workspace_save
}

workspace_remove() {
# Remove workspace
    unset ${!workspace_link_*}
    rm $workspace_dir/log/$workspace_log
    workspace_activate "default"
}

workspace_remove_all() {
# Remove all workspaces
    unset ${!workspace_link_*}
    rm $workspace_dir/log/*
    workspace_activate "default"
    workspace_save
}

workspace_add_link() {
# Add link to active workspace
# @param Link name
# @param Target directory
    local workspace_cmd="export workspace_link_$1='$2'"
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
        if [ "$ws" == $workspace_log ]; then
            echo -n -e "${s}$ws${e} "
        else
            echo -n -e "$ws "
        fi;
    done;
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
    workspace_confirm "Remove current workspace ($workspace_log)"
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

workspace_empty_current_confirm() { 
# Empty the current workspace (removing all links)
    workspace_confirm "Empty workspace ($workspace_log)"
    if [ $? == 1 ]; then
        echo "Nothing done"
        return
    fi
    workspace_empty_current
    echo "Workspace ($workspace_log) cleared"
}

workspace_helptext() {
    echo "Assuming w is an alias for \"source /path/to/workspace.sh\""
    echo "Usage: w                       List workspaces"
    echo "   or: w cw [<workspace_name>] Change workspace, if <workspace_name> is omitted, default workspace is activated"
    echo "   or: w ln <name>             Add link to current directory in active workspace"
    echo "   or: w rm [<name>]           Remove directory from workspace, or remove entire workspace if <name> is omitted"
    echo "   or: w empty                 Empty current workspace (removing all links)"
    echo "   or: w reset                 Remove all workspaces"
    echo "   or: w cd <name>             Change directory"
    echo "   or: w ls                    List all directories in workspace"
    echo "   or: w help                  Display this.."
}

workspace_run() {
    workspace_load

    # Add
    if [ "$workspace_command" == 'ln' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_add_link $workspace_name "`pwd`"
        else
            workspace_helptext
        fi

    # Remove
    elif [ "$workspace_command" == 'rm' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_remove_link $workspace_name
        else
            workspace_remove_confirm
        fi

    # Change directory
    elif [ "$workspace_command" == 'cd' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_change_directory_confirm $workspace_name
        else
            workspace_helptext
        fi

    # Change workspace
    elif [ "$workspace_command" == 'cw' ]; then
        if [ -n "$workspace_name" ]; then
            workspace_change $workspace_name
        else
            workspace_change default
        fi

    # Reset (remove all workspaces)
    elif [ "$workspace_command" == 'reset' ]; then
        workspace_remove_all_confirm $workspace_name

    # Empty workspace
    elif [ "$workspace_command" == 'empty' ]; then
        workspace_empty_current_confirm

    # List links
    elif [ "$workspace_command" == 'ls' ]; then
        workspace_list_links

    # Help
    elif [ "$workspace_command" == 'help' ]; then
        workspace_helptext

    # List workspaces
    elif [ -z "$workspace_command" ]; then
        workspace_list

    # Default
    else
        workspace_helptext
    fi
}

workspace_run
