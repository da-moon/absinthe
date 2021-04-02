# Usage: wsl-up new <name> [options]
# Summary: new wsl environment
# Help: spins up a new wsl environment:
#      wsl-up new alpine
#
# Options:
#   -m, --minimal             do not provision the distro with default tools
#   -d, --distro <alpine>     Use the specified distro root file system

. "$psscriptroot\..\lib\core.ps1"
. "$psscriptroot\..\lib\help.ps1"
. "$psscriptroot\..\lib\getopt.ps1"
. "$psscriptroot\..\lib\new.ps1"

reset_aliases

$opt, $name, $err = getopt $args 'md:' 'minimal', 'distro='
if ($err) { "wsl-up new: $err"; exit 1 }
$minimal = $opt.m -or $opt.minimal
$distro = 'alpine'
try {
    $distro = ensure_distro ($opt.d + $opt.distro)
} catch {
    abort "ERROR: $_"
}

if (!$name) { error '<name> missing'; my_usage; exit 1 }

# if ($global -and !(is_admin)) {
#     abort 'ERROR: you need admin rights to install global apps'
# }
if ($name.length -gt 1) {
  try {
    throw [System.ArgumentException] "multiple names were given: '$name'"
  } catch {
    abort "ERROR: $_"
  }
}
warn "name=$name
distro=$distro
minimal=$minimal
"
exit 0
