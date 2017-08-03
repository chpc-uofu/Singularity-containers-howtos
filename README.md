# Singularity at CHPC, University of Utah

## A few notes on singularity installation

Singularity installation requires root, so, our admins need to install it in our sys branch as described [here](http://singularity.lbl.gov/docs-quick-start-installation).

Local changes done by root include:
- create /var/lib/singularity/mnt on each Linux machine that's expecting to run container images - should be in Spacewalk
- sudo access for "singularity" command for User Services

Local changes done by hpcapps:
- create singularity module file - just adding path to singularity bin directory

## Container deployment 

### Basic info

To create a container, one needs to first create the image:
```
sudo singularity create --size 4096 ubuntu_$imgname.img
```
and then bootstrap (install) the OS, and other needed programs:
```
sudo singularity bootstrap ubuntu_$imgname.img ubuntu_$imgname.def
```
I prefer to have a script, called [`build_container.sh`](https://github.com/mcuma/chpc_singularity/blob/master/seqlinkage/build_container.sh) that calls these two commands.

The container definition file describes the bootstrap process, described [here](http://singularity.lbl.gov/bootstrap-image). 

To create a new container, the easiest is to get one of the definition files and modify accordingly. Singularity has some examples [here](https://github.com/singularityware/singularity/tree/master/examples), or start from the examples on this git page.

Effort should be made to make the container building non-interactive, so they can be automatically rebuilt. Singularity developers also encourage doing everything from the def file, rather than launching `singularity exec` to add stuff to the container. 

### Container build strategy
The strategy that I found works reasonably well is to bootstrap the base OS image, `singularity shell` into the container and then manually execute commands to build the particular package, while writing them down in a shell script. Oftentimes the packages have some kinds of shell scripts that install dependencies, and the program itself. Though, it can take time to iterate over and fix issues, mostly related to missing dependencies. Once things work, paste commands from this shell script as a scriptlet to the `%post` section of the def file. 

To launch a shell in the new image, `sudo singularity shell -w -s /bin/bash myimage.img`, `-w` makes the image writeable, `-s` makes shell bash (easier to use than default sh). In the container, use `apt-get` or `yum` to install the required dependencies (when something is missing, google what package contains it), and finally `wget` the install files for the program, or download them to a local directory, and add `-B `pwd`:/mnt` to the `singularity shell` command to mount the local directory under `/mnt` in the container.

Once the application in the container is installed, and the scriptlet in the def file to do this installation is written, build the container again. If there's an error, fix it and iterate over, until the container builds with no error.

If install files need to be brought in from the host OS, including files that need to be downloaded interactively (e.g. CUDA installer) use the `%setup` section, which runs on the host. To put files in the container, use `${SINGULARITY_ROOTFS}`. E.g. to put files to container's `/usr/local`, put it to `${SINGULARITY_ROOTFS}/usr/local`. Example of this is [our tensorflow def file](https://github.com/CHPC-UofU/Singularity-tensorflow/blob/master/Singularity).

To test the installation, use the `%test` section to put there commands that run tests.

### A few tips
- make sure to create mount points for CHPC file servers:
```
    mkdir /uufs
    mkdir /scratch
```
- additions to default environment (PATH, LD_LIBRARY_PATH) can be put to /environment file in the container, e.g.
``` echo "
    PATH=my_new_path:\$PATH
    export PATH
    " >> /environment
```
- if a non-root installation is needed (e.g. LinuxBrew), then create the non-root user and use `su -c 'command' user` to do the non-root stuff, e.g.
```
    useradd -m brewuser
    su -c 'brew install freetype --build-from-source' brewuser
```
See [our bioBakery def file](https://github.com/CHPC-UofU/Singularity-bioBakery/blob/master/Singularity) for full definition file that shows this.
- if any of the bootstrap commands exits with non-zero status, container build will terminate. While this is good to catch build issues, sometimes we want to ignore known errors. The simplest way to set exit status to zero is to pipe it to `true`, e.g. to overcome a known LinuxBrew error where the first update fails:
```
/opt/linuxbrew/bin/brew update || true ; /opt/linuxbrew/bin/brew update 
```
If we want to return the result of the command in case of zero exit status, but catch the non-zero exit status, wrap it in a condition, e.g. in the example below, if there's no `proxy` in `env`, the `env | grep proxy` will have non-zero exit status:
```
if env | grep -q proxy; then env | grep proxy; fi
```

### A few caveats that I found
- `%test` section does not seem to bring environment from /environment created in `%post` section, so, make sure to define PATH and LD_LIBRARY_PATH in the `%test` section before running tests.
- the `%post` section starts at `/` directory, so, cd to some other directory (e.g. `/root`) before building programs.
- to support NVidia GPUs in the container, one needs to instal a few NVidia driver libraries of the same version as the host driver. To find the version, run `rpm -qa | grep nvidia`. Then either follow [our tensorflow def file](https://github.com/CHPC-UofU/Singularity-bioBakery/blob/master/Singularity) or bring libcuda.so and libnvidia-fatbinaryloader.so from the host.
- to support InfiniBand, need to install the IB driver stack in the container and make sure the driver sos are in the LD_LIBRARY_PATH (see the ubuntu_mpi container recipe for details).
- Singularity container inherits the environment from the host shell, including PATH. One needs to be aware of this when setting things up. E.g. starting the container from a fairly clean environment may be a good idea. The only thing that it does not inherit are
 -- LD_LIBRARY_PATH
 -- shell functions (e.g. LMod defines its commands via shell functions)
- supporting modules (LMod) requires separate LMod installation for Ubuntu based containers and a few other modifications, detailed below

## Running the container

Singularity container is an executable so it can be run as is (which launches whatever is in `%runscript` section), or with `singularity exec` followed by the command within container, e.g.:
```
singularity exec -B /scratch debian_SEQLinkage.img seqlink [parameters]
singularity run debian_SEQLinkage.img
```
If more than one command are needed to be executed in the container, one can run `singularity shell`, e.g.
```
singularity shell -s /bin/bash -B /scratch /ubuntu_biobakery.img
```
To specify the shell to use (default /bin/sh is not very friendly), use the `-s` flag or environment variable `SINGULARITY_SHELL=/bin/bash`.

### Binding file systems

- home directory gets imported (bound) to the image automatically as long as the `/uufs` mount point is created.
- all scratches get imported when using `-B /scratch` option
- to bring in sub-directories of `/uufs`, such as the sys branch, add `-B /uufs/chpc.utah.edu`.

That is, to bring in home dir, scratches and the sys branch, we'd launch the container as
```
singularity shell -B /scratch -B /uufs/chpc.utah.edu -s /bin/bash ubuntu_tensorflow_gpu.img
```
Alternatively, use environment variable `SINGULARITY_BINDPATH="/scratch,/uufs/chpc.utah.edu"`.

### Including LMod support

Modules support pulling programs from CHPC sys branch may be useful for some containers. In particular, we can use the Intel compiler/MPI stack to build MPI programs in the container, or use Intel Python Distribution. Both are built in distro-agnostic fashion so if installed on CentOS, they work on e.g. Ubuntu.

This description is for Ubuntu based containers, for CentOS, sys branch LMod works with the CHPC CentOS7 LMod installation after re-initializing LMod (because the shell functions don't get passed to the container).
For Ubuntu containers, we need to do the following
- have LMod installed in the sys branch using Ubuntu - can be done from the container
 -- now /uufs/chpc.utah.edu/sys/installdir/lmod/7.4-u16/
 -- need to have specific Ubuntu install since some commands (tr, lua) and Lua libraries have different location on Ubuntu than on CentOS
 - when building the container, set environment variable SINGULARITY_MOD=1
 - the user needs to have the following at the end of ~/.custom.sh:
```
export OSVER=`lsb_release -r | awk '{ print $2; }'`
export OSREL=`lsb_release -i | awk '{ print $3; }'`

if [ -n "$SINGULARITY_CONTAINER" ] && [ -n "$SINGULARITY_MOD" ]; then
  if [ $OSREL == "CentOS" ]; then # assume only CentOS7
    source /uufs/chpc.utah.edu/sys/installdir/lmod/7.1.6-c7/init/bash
  elif [ $OSREL == "Ubuntu" ]; then # assume only Ubuntu 16
    source /uufs/chpc.utah.edu/sys/modulefiles/scripts/clear_lmod.sh
    source /uufs/chpc.utah.edu/sys/installdir/lmod/7.4-u16/init/profile
  fi
fi
```
- the container needs to be started with binding the sys branch, i.e. with `-B /uufs/chpc.utah.edu`

For example of container that has the LMod support built in, see [Ubuntu Python container](https://github.com/CHPC-UofU/Singularity-ubuntu-python).

## Deploying the container

- copy the definition file and other potential needed files to the srcdir 
- copy the container image (img file) to installdir
- create module file that wraps the package call through the container, for example see [SEQLinkage module file](https://github.com/CHPC-UofU/Singularity-SEQLinkage/blob/master/1.0.0.lua).
- create SLURM batch script example, for example see [SEQLinkage batch script]/(https://github.com/CHPC-UofU/Singularity-SEQLinkage/blob/master/run_seqlink.slr)
-- NOTE that LMod does not expand alias correctly in bash non-interactive shell, so, use tcsh for the SLURM batch scripts until this is resolved


## Things to still look at

- running MPI programs that are in the container - IMHO unless the application is really difficult to build, stick to host based execution - works, see ubuntu_mpi
- including sys branch tools like MKL in the container for better performance
 -- can supply Ubuntu's OpenBlas under numpy - need to test performance
- running X applications out of the container - works, but, OpenGL is questionable
