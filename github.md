# CHPC's Singularity files on Github and local Gitlab

Public GitHub CHPC's organization page is named *CHPC-UofU*. This is a primary location for CHPC public facing files, including the container definitions. GitHub is also needed for integration with [singularity-hub.org](Singularity Hub). In order for Singularity Hub to see the repos from *CHPC-UofU*, we had to allow *Third-party application access* to the organization via *CHPC-UofU*-*Settings*-*Third-party access*.

For container definitions, we also use the GitHub repositories to GitLab's *Singularity* group. The original though was for GitLab to automatically mirror the GitHub, but, this feature is only available in GitHub EE. Therefore, instead, we overload each local repository origin with two remotes, as described [https://steveperkins.com/migrating-projects-from-github-to-gitlab/](here).

Each container will thus have its own repository on GitHub's *CHPC-UofU* organization page, and on GitLab *Singularity* group page.

### GIT setup

We need to have accounts on GitHub and CHPC's GitLab and enable SSH keys to both servers for passwordless interaction.

#### GitHub
- create github.com account if you don't have one by navigating web browser to github.com
- e-mail Martin to be added to the *CHPC-UofU* organization
- create SSH keys for passwordless access to github.com, as described [https://help.github.com/articles/connecting-to-github-with-ssh/](here)

#### GitLab
- open gitlab.chpc.utah.edu in your web browser and authenticate with uNID
- create SSH keys by going to your user settings (pulldown menu accessed via use icon in the upper right corner), then choosing *SSH Keys* and following the instructions.

### Files in container repository

#### Each container repo should at least contain:
- the container definition file - `Singularity`. The name, `Singularity`, is mandatory, as it allows for integration with [Singularity Hub](https://singularity-hub.org/).
- shell script that runs the Singularity commands to build the container - usually just two lines, first creating the container of a given size, and second which does the bootstrap
- `readme.md` - which describes what is this container for, tips/tricks in container setup and useful external files/links and 
- `.gitignore` - at the very least include there *.img to ignore the container image files

#### Optional files include
- LMod module for the container
- SLURM batch script to run the container, or commands from the container

### Creating container repository
Once we have our container files together, and the container builds OK, we can include it in the GIT in the following steps:

1. Create a local repository. 
 - make sure that there's only one container per repository
 - use `.gitignore` from existing repos as a start for local .gitignore
 - then run the following commands:
```
 git init
 git add .
 git commit -m "initial commit"
```

2. Create a remote GitHub repository and put the local repo to it
 - go to github.com, select *CHPC-UofU* as organization, create new repo under this organization (can't figure out how to do this via a command line)
 - run the following command:
```
 git remote add origin git@github.com:CHPC-UofU/Singularity-REPO.git
```
 - Singularity-REPO.git is the repo name

3. Create GitLab repository and add it to the local repo
 - go to gitlab.chpc.utah.edu, go to Singularity group, and there create a new repo.
 - add gitlab remote to the local repo 
```
 git remote set-url --add origin git@gitlab.chpc.utah.edu:Singularity/Singularity-REPO.git
```
 - Singularity-REPO.git is the repo name

4. Push the image 
```
 git push -u origin master
```

### Some tips/tricks

#### To selectively add initial files:
```
ls -1 > files
edit files to remove what's not needed
git add `cat files` 
```

#### Modifying a container repo
```
git clone git@github.com:CHPC-UofU/Singularity-tensorflow.git
cd Singularity-tensorflow/
cp ../.gitignore .

# do your modifications, e.g.
mv Singularity.def Singularity
git rm --cached Singularity.def

git remote set-url --add origin  git@gitlab.chpc.utah.edu:Singularity/Singularity-tensorflow.git
git commit -a -m "add gitlab"
git push -u origin master
```


