
bash-workspace
==============

Installation
------------

If you use the directory ~/.workspace for something, open workspace.sh and 
change `workspace_dir=...` to something else.

Create an alias for this script (using "source" so that it's allowed to change directories):

    alias w='source /path/to/workspace.sh'

Add the preceding line to ~/.bashrc to make it permanent.

Usage
-----

### Get a list of all available commands (assuming you defined an alias as in step 2)
    w help

### Example: Working on a project named awesome

#### File structure:

- Root folder: ~/project/awesome
- Test folder: ~/project/awesome/test/src
- Main folder: ~/project/awesome/main/src

#### Use case: Working in two directories, main and test

1. Create, and activate a new workspace named awesome

        w use awesome

2. Move into the project folder

    cd ~/projects/awesome

3. Add a link to the current directory and name it "r"

    w add r 

4. Move into the test folder, and add a link named "test"

    cd test/src
    w add test

5. Do some work in the test folder (writing unit tests?)

6. Go back to the root directory
    w cd r        

7. Move into the main folder, and add a link named "main"

    cd main/src
    w add test

9. Do some work (make the tests run?)

10. Go back to the test directory

    w cd test

11. Make more tests, and get bored

12. Start working on another project (conveniently named project2)

    w use project2
    w ls      # List all links for the current project
    w clear   # Remove all links from the current project
    # do some work, add some links, remove some, decide to scrap the project ...
    w remove  # Remove the current project

10. Logout, go to sleep, login again and start working on the awesome project

    w                 # lists all workspaces
    w use awesome     # Use the awesome project 
                      # (links still stored under ~/.workspace/log/awesome)
    w cd main         # Go to main
