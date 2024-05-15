-- -*- lua -*-
-- CHPC template for Container module file
-- modify only items noted
help(
[[
Any help you want to display when running "module help module-name"
]])

-- path to the container sif file
local CONTAINER="/uufs/chpc.utah.edu/common/home/u0123456/containers/mycontainer.sif"
-- text array of commands to alias from the container
local COMMANDS = {"command1","command2","command3"}
-- set to true if the container requires GPU(s)
local GPU = false

-- these optional lines provide more information about the program in this module file
whatis("Name         : program-name")
whatis("Version      : x.x.x")
whatis("Category     : category of program, e.g. genomics, visualization, etc.")
whatis("URL          : URL of the program")
whatis("Installed on : xx/xx/20xx")
whatis("Installed by : your name")

-- do not modify anything below this line
depends_on("apptainer")

if GPU then
  nvswitch = '--nv '
  setenv("APPTAINER_NV","true")
  add_property("arch","gpu")
else
  nvswitch = ''
end

local run_shell = 'singularity shell ' .. nvswitch .. '-s /bin/bash ' .. CONTAINER
-- container is executable, so can run as "container.sif command"
local run_function = CONTAINER .. " " 
-- set shell access to the container with "containerShell" command
set_shell_function("containerShell",run_shell,run_shell)

-- loop over COMMANDS array to create the shell functions
for ic,program in pairs(COMMANDS) do
  set_shell_function(program, run_function .. program .. " $@",run_function .. program .. " $*")
end

-- to export the shell function to a subshell
if (myShellName() == "bash") then
  execute{cmd="export -f containerShell",modeA={"load"}}
  execute{cmd="export -f " .. table.concat(COMMANDS, " "),modeA={"load"}}
-- newer Lmod unsets this automatically upon unload
-- execute{cmd="unset -f containerShell",modeA={"unload"}}
-- execute{cmd="unset -f " .. table.concat(COMMANDS, " "),modeA={"unload"}}
end



