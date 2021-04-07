#requires -v 3

# powershell -executionpolicy bypass -File bin\wsl-up.ps1
# pwsh -executionpolicy bypass -File bin/wsl-up.ps1

param($cmd)

set-strictmode -off

. "$psscriptroot\..\lib\core.ps1"
. "$psscriptroot\..\lib\messages.ps1"
. "$psscriptroot\..\lib\commands.ps1"

reset_aliases

$commands = commands
if ('--version' -contains $cmd -or (!$cmd -and '-v' -contains $args)) {
    write-host "v0.0.1"
}
elseif (@($null, '--help', '/?') -contains $cmd -or $args[0] -contains '-h') { exec 'help' $args }
elseif ($commands -contains $cmd) { exec $cmd $args }
else { "wsl-up: '$cmd' isn't a wsl-up command. See 'wsl-up help'."; exit 1 }
