
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

Add the following to ~/.bashrc
    alias w='source /home/stianlik/Prosjekter/bash-workspace/workspace.sh'
    w autocomplete # If you chose another alias, run <another_alias> autocomplete <another_alias>

Usage
-----

If you type `w `, auto-complete will suggest all available commands.

## Change workspace (it will be created if id doesn't already exist)

Auto-complete will suggest available workspaces, including the 
current directory name

    w cw my_workspace

## Add link to current directory

Auto-complete will suggest the current directory name

    w ln some_link_name

## Move to workspace root

    w cd

## Move to linked folder

Auto-complete will suggest links added using `w ln`
    
    w cd some_link_name

## Remove a shortcut from the active workspace 

Auto-complete will suggest links added using `w ln`
    
    w rm <name>

## Clear the current workspace (i.e. delete all shortcuts for this workspace) 
    
    w empty

## Remove the current workspace 
    
    w rm

## Remove all workspaces and shortcuts 

    w reset

## List all shortcuts for the active workspace 

    w list

## List all stored workspaces 

    w

## Get help

    w help
