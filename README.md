
bash-workspace
==============

Overview
--------

bash-workspace makes it easy to navigate the filesystem using context sensitive shortcuts.

This script implements workspaces for the terminal. The idea is to create one workspace per 
project (or context), and store a bunch of shortcuts to relevant folders in each workspace so 
that you quickly can jump from place to place.

Workspaces, including all shortcuts are stored in `~/.bash-workspace/log/<workspace-name>`.
This let you access your workspaces between sessions (in multiple terminals, etc.).

Installation
------------

1. Download workspace.sh and place it in `/some/path/workspace.sh`

2. Add the following to `~/.bashrc`

        alias bws='source /some/path/workspace.sh'
        bws autocomplete # If you chose another alias, run <another_alias> autocomplete <another_alias>

Usage
-----

If you type `bws ` and click tab twice auto-complete will suggest all available commands.

### Change workspace (it will be created if id doesn't already exist)

Auto-complete will suggest available workspaces, including the 
current directory name

    bws cw my_workspace

### Add link to current directory

Auto-complete will suggest the current directory name

    bws ln some_link_name

### Move to workspace root

    bws cd

### Move to linked folder

Auto-complete will suggest links added using `bws ln`
    
    bws cd some_link_name

### Remove a shortcut from the active workspace 

Auto-complete will suggest links added using `bws ln`
    
    bws rm <name>

### Clear the current workspace (i.e. delete all shortcuts for this workspace) 
    
    bws empty

### Remove the current workspace 
    
    bws rm

### Remove all workspaces and shortcuts 

    bws reset

### List all shortcuts for the active workspace 

    bws list

### List all stored workspaces 

    bws

### Get help

For more information (including commands I didn't include here):

    bws help
