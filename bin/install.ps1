# ────────────────────────────────────────────────────────────────────────────────
#
# ─── LOCAL INSTALL ──────────────────────────────────────────────────────────────
#
# powershell -executionpolicy bypass -File bin\install.ps1
# ────────────────────────────────────────────────────────────────────────────────
# 
#
# ─── REMOTE INSTALL ─────────────────────────────────────────────────────────────
#
#	Set-ExecutionPolicy RemoteSigned -scope CurrentUser
#	iwr -useb 'https://raw.githubusercontent.com/da-moon/wsl-up/master/bin/install.ps1'| iex
# ────────────────────────────────────────────────────────────────────────────────
# [ NOTE ] => heavily inspired by scoop
# https://github.com/lukesampson/scoop/blob/master/bin/install.ps1
# ────────────────────────────────────────────────────────────────────────────────
# [ NOTE ] => Check OS and ensure we are running on Windows
if (-Not ($Env:OS -eq "Windows_NT")) {
  Write-Host "Error: This script only supports Windows machines. Exiting..."
  exit 1
}

$old_erroractionpreference = $erroractionpreference
$erroractionpreference = 'stop' # quit if anything goes wrong

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Output "PowerShell 5 or later is required to run wsl-up."
    Write-Output "Upgrade PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell"
    break
}

# [ NOTE ] => show notification to change execution policy:
$allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
    Write-Output "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ", ")] to run wsl-up."
    Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
    Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"
    break
}

# if ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -notcontains 'Tls12') {
#     Write-Output "Scoop requires at least .NET Framework 4.5"
#     Write-Output "Please download and install it first:"
#     Write-Output "https://www.microsoft.com/net/download"
#     break
# }

# ────────────────────────────────────────────────────────────────────────────────
# 
# ─── GET CORE FUNCTIONS ─────────────────────────────────────────────────────────
#
$library_repo_root_url = "https://raw.githubusercontent.com/da-moon/wsl-up/master/lib"
Write-Output 'Initializing...'
$libraries = @("messages","core","shim")
foreach ($library in $libraries) {
  $target = $library_repo_root_url + '/' + "$library" + ".ps1"
  Invoke-Expression (new-object net.webclient).downloadstring($target)
}
# ────────────────────────────────────────────────────────────────────────────────
#
# ─── DOWNLOADING WSL-UP ─────────────────────────────────────────────────────────
#
$tmp_dir="$Env:TEMP\wsl-up"
info "downloading wsl-up zip file"
$zipurl = 'https://github.com/da-moon/wsl-up/archive/master.zip'
$zipfile = "$tmp_dir\wsl-up.zip"
info "Downloading wsl-up zip file and storing it in '$tmp_dir'"
dl $zipurl $zipfile
# ────────────────────────────────────────────────────────────────────────────────
#
# ─── EXTRACTING ─────────────────────────────────────────────────────────────────
#
info 'Extracting wsl-up'
Add-Type -Assembly "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($zipfile, "$tmp_dir")
# ────────────────────────────────────────────────────────────────────────────────
if ((Test-Path -Path $wsl_up_dir -PathType Container)) {
  warn "wsl-up install directory [$wsl_up_dir] exists.trying to remove it for a fresh install."
  $null = Remove-Item "$wsl_up_dir" -Recurse -Force -ErrorAction Stop
  info "wsl-up install directory [$wsl_up_dir] has been deleted."
}
info "ensuring install directory [$wsl_up_dir] exists"
$null = New-Item -ItemType Directory -Path $wsl_up_dir -Force -ErrorAction Stop
info "copying files to install directory [$wsl_up_dir]"
Copy-Item "$tmp_dir\*master\*" $wsl_up_dir -Recurse -Force
info "cleaning up"
$null = Remove-Item "$tmp_dir" -Recurse -Force -ErrorAction Stop
# ────────────────────────────────────────────────────────────────────────────────
$shim_path="$wsl_up_dir\bin\wsl-up.ps1"
info "creating shim for '$shim_path'"
create_shim $shim_path
# ────────────────────────────────────────────────────────────────────────────────
success "wsl-up was installed"