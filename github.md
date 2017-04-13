# CHPC's Singularity files on Github and local Gitlab

Public GitHub CHPC's organization page is named *CHPC-UofU*. It is owned by Martin, e-mail him to get invited to it. This is a primary location for CHPC public facing files, including the container definitions.

For container definitions, we mirror the GitHub repositories to GitLab's *Singularity* group

Each container will have its own repository on GitHub's *CHPC-UofU* organization page, and on GitLab *Singularity* group page.

### Files in container repository

#### Each container repo should at least contain:
- the container definition file - `Singularity.def`. The name, `Singularity.def`, is mandatory, as it allows for integration with [Singularity Hub](https://singularity-hub.org/).
- shell script that runs the Singularity commands to build the container - usually just two lines, first creating the container of a given size, and second which does the bootstrap
- readme.md - which describes what is this container for, tips/tricks in container setup and useful external files/links and 

#### Optional files include
- LMod module for the container
- SLURM batch script to run the container, or commands from the container

### Creating container repository
Once we have our container files together, and the container builds OK, we can include it in the GIT in the following steps:

1. Create a local repository. 
 - make sure that there's only one container per repository
 - use `.gitignore` from existing repos as a start for local `.gitignore` - at the very least include there `*.img` to ignore the container image files
 - then run the following commands:
 ```
 git init
 git add .
 git commit -m "initial commit"
```
2. Create a remote GitHub repository and put the local repo to it
 - go to github.com, select CHPC-UofU as organization, create new repo under this organization (can't figure out how to do this via a command line)
 - run the following commands
 ```
 git remote add origin https://USER@github.com/CHPC-UofU/Singularity-REPO.git
 git push -u origin master
 ```
 - USER is your GitHub user name, Singularity-REPO.git is the repo name

3. Mirror this repo to CHPC GitLab
 - select *Singularity* group and and in this group create a new project
 - choose to import, 
 - at first time, it'll ask for token to access github - generate it and paste to the gitlab page
 - select the appropriate repo from github to import
 - make sure in the *To GitLab* column, *Singularity* is selected (default is your uNID), then hit Import


