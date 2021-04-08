# Usage: wsl-up new <name> [options]
# Summary: new standalone wsl environment
# Help: spins up a new wsl environment:
#      wsl-up new alpine
#
# Options:
#   -m, --minimal                 [OPTIONAL] do not provision the distro with default tools
#   -u, --update                  [OPTIONAL] updated distro's local base filesystem
#   -f, --filesystem              [OPTIONAL] path to base root file system
#   -d, --distro <arch|alpine>    [OPTIONAL] Use the specified distro root file system.

. "$psscriptroot\..\lib\messages.ps1"
. "$psscriptroot\..\lib\core.ps1"
. "$psscriptroot\..\lib\alias.ps1"
. "$psscriptroot\..\lib\help.ps1"
. "$psscriptroot\..\lib\getopt.ps1"
. "$psscriptroot\..\lib\distro.ps1"
. "$psscriptroot\..\lib\network-io.ps1"

reset_aliases
if ( -Not (Get-Command "wsl" -ErrorAction Ignore) ) {
  abort "ERROR: 'wsl' was not found in PATH."
}

$opt, $name, $err = getopt $args 'mufd:' 'minimal', 'update', 'filesystem' , 'distro='
if ($err) { "wsl-up new: $err"; exit 1 }
$minimal = $opt.m -or $opt.minimal
$update = $opt.u -or $opt.update
$filesystem = $opt.f -or $opt.filesystem
$distro = 'alpine'
try {
    $distro = ensure_distro ($opt.d + $opt.distro)
} catch {
    abort "ERROR: $_"
}
if (!$name) { error '<name> missing'; my_usage; exit 1 }

if ($name.length -gt 1) {
  try {
    throw [System.ArgumentException] "multiple names were given: '$name'"
  } catch {
    abort "ERROR: $_"
  }
}
if ( -Not (Get-Command "aria2c" -ErrorAction Ignore) )  {
  warn "wsl-up prefers to use 'aria2c' for multi-connection downloads."
  warn "please install it as it was not detected in path."
}
$url = (filesystem_url "$distro")
if (!$filesystem) {
  $file_name = Split-Path -Path "$url" -Leaf
  $filesystem = $wsl_up_dir + "\cache\$file_name"
}
if ($update) {
  Remove-Item "$filesystem" -Force -ErrorAction SilentlyContinue
}
if (-not(Test-Path -Path $filesystem -PathType Leaf)) {
  warn "root file system for [$distro] was not found at [$filesystem]."
  info "downloading root file system from [$url]"
  download $url  $filesystem
}

info "Setting up wsl environment"
info "name='wsl-up-$distro-$name'"
info "location='$wsl_up_dir\$name'"
wsl --import "wsl-up-$distro-$name" "$wsl_up_dir\$name" $filesystem
wsl --list
exit 0
# tar -xf $filesystem
# tar -czaf arch-wsl.tar.gz root.x86_64/*