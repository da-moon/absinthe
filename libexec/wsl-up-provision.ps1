# Usage: wsl-up provision <name> [options]
# Summary: provisions a standalone wsl environment
# Help: provisions an already existing wsl environment:
#      wsl-up provision alpine
#
# Options:
#   -s, --skip-package        skips installing given packages
#   -i, --include-package     includes package to install
#   -r, --remove-package      uninstalls given packages to install
#   -u, --user                creates a user

. "$psscriptroot\..\lib\core.ps1"
. "$psscriptroot\..\lib\help.ps1"
. "$psscriptroot\..\lib\getopt.ps1"
. "$psscriptroot\..\lib\provision.ps1"

reset_aliases

$opt, $name, $err = getopt $args 'siru:' 'skip-package', 'include-package','remove-package','user'
if ($err) { "wsl-up provision: $err"; exit 1 }
$skip_package = $opt.s -or $opt.skip-package
$include_package = $opt.i -or $opt.include_package
$remove_package = $opt.r -or $opt.remove_package
$user = $opt.u -or $opt.user

if (!$name) { error '<name> missing'; my_usage; exit 1 }
if ($name.length -gt 1) {
  try {
    throw [System.ArgumentException] "multiple names were given: '$name'"
  } catch {
    abort "ERROR: $_"
  }
}
warn "name=$name
skip_package=$skip_package
include_package=$include_package
remove_package=$remove_package
user=$user
"
exit 0
