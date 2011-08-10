#!/bin/bash
#
# Author Stian Liknes <stianlik@gmail.com>
# Created: 2011-08-10
#

workspace_dir=~/.workspace

mkdir $workspace_dir > /dev/null 2>&1
mkdir $workspace_dir/log> /dev/null 2>&1

workspace_command=$1
workspace_name=$2

source $workspace_dir/current 2> /dev/null
if [ -z "$workspace_log" ]; then
    workspace_log=default
fi;

workspace_helptext() {
    echo "Usage: workspace                          List workspaces"
    echo "   or: workspace use <workspace_name>     Change workspace"
    echo "   or: workspace add <name>               Add current directory to workspace"
    echo "   or: workspace rm [<name>]              Remove directory from workspace, or remove entire workspace if <name> is omitted"
    echo "   or: workspace clear                    Clear current workspace (removing all links)"
    echo "   or: workspace cd <name>                Change directory"
    echo "   or: workspace ls                       List all directories in workspace"
    echo "   or: workspace help                     Display this.."
}

workspace_load() {
    unset ${!workspace_link_*}
    source $workspace_dir/log/$workspace_log 2> /dev/null
    echo `export -p | grep workspace_link_ | sed -e 's/.*\?workspace_link_/export workspace_link_/g'` > $workspace_dir/log/$workspace_log
}

workspace_clear() {
    echo -n "Clear workspace ($workspace_log) (Yes/No)? "
    read clear_workspace
    local clear_workspace=`echo $clear_workspace | tr '[:upper:]' '[:lower:]'`
    if [ "$clear_workspace" == "yes" ] || [ "$clear_workspace" == "y" ]; then
        echo " " > $workspace_dir/log/$workspace_log
        echo "Workspace ($workspace_log) cleared"
    else
        echo "Nothing done"
    fi;
}

workspace_remove_all() {
    echo -n "Remove current workspace ($workspace_log) (Yes/No)? "
    read remove_workspace
    local remove_workspace=`echo $remove_workspace | tr '[:upper:]' '[:lower:]'`
    if [ "$remove_workspace" == "yes" ] || [ "$remove_workspace" == "y" ]; then
        rm $workspace_dir/log/$workspace_log
        echo "Workspace ($workspace_log) removed"
        workspace_log=default
        echo "Default workspace activated"
    else
        echo "Nothing done"
    fi;
}

workspace_list_workspaces() {
    #local s="\033[40m\033[1;34m"
    #local e="\033[0m"
    local s="["
    local e="]"
    for ws in `ls $workspace_dir/log`; do
        if [ "$ws" == $workspace_log ]; then
            echo -n -e "${s}$ws${e} "
        else
            echo -n -e "$ws "
        fi;
    done;
    echo
}

workspace_load

if [ "$workspace_command" == 'add' ]; then
    if [ -n "$workspace_name" ]; then
        workspace_cmd="export workspace_link_$workspace_name='`pwd`'"
        echo $workspace_cmd >> $workspace_dir/log/$workspace_log
    else
        workspace_helptext
    fi

elif [ "$workspace_command" == 'rm' ]; then
    if [ -n "$workspace_name" ]; then
        workspace_cmd="unset workspace_link_$workspace_name"
        echo $workspace_cmd >> $workspace_dir/log/$workspace_log
    else
        workspace_remove_all
    fi

elif [ "$workspace_command" == 'clear' ]; then
    workspace_clear

elif [ "$workspace_command" == 'cd' ]; then
    if [ -n "$workspace_name" ]; then
        workspace_path=workspace_link_$workspace_name;
        workspace_path=${!workspace_path}
        if [ -n "$workspace_path" ]; then
            cd $workspace_path;
        else
            echo "Could not find workspace ('$workspace_name')"
        fi
    else
        workspace_helptext
    fi

elif [ "$workspace_command" == 'use' ]; then
    if [ -n "$workspace_name" ]; then
        export workspace_log=$workspace_name
        echo "Current workspace: $workspace_log"
    else
        echo "Current workspace: $workspace_log"
    fi

elif [ "$workspace_command" == 'help' ]; then
    workspace_helptext

elif [ "$workspace_command" == 'ls' ]; then
    export -p | grep workspace_link_ | sed -e 's/.*\?workspace_link_//g'

elif [ -z "$workspace_command" ]; then
    workspace_list_workspaces

else
    workspace_helptext
fi

echo "export workspace_log=$workspace_log" > $workspace_dir/current
