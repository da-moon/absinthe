#
# ─── SHIM ───────────────────────────────────────────────────────────────────────
#
# [ NOTE ] =>
# https://github.com/lukesampson/psutils/blob/master/shim.ps1
. "$psscriptroot\messages.ps1"
. "$psscriptroot\core.ps1"
. "$psscriptroot\path.ps1"

function env($name, $global, $val = '__get') {
  $target = 'User'; if ($global) { $target = 'Machine' }
  if ($val -eq '__get') { [environment]::getEnvironmentVariable($name, $target) }
  else { [environment]::setEnvironmentVariable($name, $val, $target) }
}
function create_shim($path) {
  if (!(Test-Path $path)) { abort "shim: couldn't find $path"; }
  $path = Resolve-Path $path
  $shimdir = "~/appdata/local/shims"
  if (-not(Test-Path $shimdir)) { 
    $null=New-Item -ItemType Directory -Path $shimdir -Force -ErrorAction Stop
  }
  $shimdir = Resolve-Path $shimdir
  ensure_in_path $shimdir

  $fname_stem = [io.path]::getfilenamewithoutextension($path).tolower()

  $shim = "$shimdir\$fname_stem.ps1"

  Write-Output "`$path = '$path'" > $shim
  Write-Output 'if($myinvocation.expectingInput) { $input | & $path @args } else { & $path @args }' >> $shim

  if ($path -match '\.((exe)|(bat)|(cmd))$') {
    info "shim .exe, .bat, .cmd so they can be used by programs with no awareness of PSH"
    "@`"$path`" %*" | Out-File "$shimdir\$fname_stem.cmd" -encoding oem
  }
  elseif ($path -match '\.ps1$') {
    info "make ps1 accessible from cmd.exe"
    "@powershell -noprofile -ex unrestricted `"& '$path' %*;exit `$lastexitcode`"" | Out-File "$shimdir\$fname_stem.cmd" -encoding oem
  }
}