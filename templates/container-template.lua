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

-- these optional lines provide more information about the program in this module file
whatis("Name         : program-name")
whatis("Version      : x.x.x")
whatis("Category     : category of program, e.g. genomics, visualization, etc.")
whatis("URL          : URL of the program")
whatis("Installed on : xx/xx/20xx")
whatis("Installed by : your name")

-- do not modify anything below this line
depends_on("singularity")
-- set shell access to the container with "containerShell" command
set_shell_function("containerShell",'singularity shell -s /bin/bash ' .. CONTAINER,"singularity shell -s /bin/bash " .. CONTAINER)

-- loop over COMMANDS array to create the shell functions
for ic in pairs(COMMANDS) do
  set_shell_function(COMMANDS[ic],'singularity exec ' .. CONTAINER .. " " .. COMMANDS[ic] .. " " .. "$@","singularity exec " .. CONTAINER .. " " .. COMMANDS[ic] .. " " .. "$*")
end

-- to export the shell function to a subshell
if (myShellName() == "bash") then
  execute{cmd="export -f containerShell",modeA={"load"}}
  -- loop over the array of commands
  for ic in pairs(COMMANDS) do
    execute{cmd="export -f " .. COMMANDS[ic],modeA={"load"}}
  end
end



