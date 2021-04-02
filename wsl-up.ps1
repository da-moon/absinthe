# Usage: scoop install <app> [options]
# Summary: Install apps
# Help: e.g. The usual way to install an app (uses your local 'buckets'):
#      scoop install git
#
# To install an app from a manifest at a URL:
#      scoop install https://raw.githubusercontent.com/ScoopInstaller/Main/master/bucket/runat.json
#
# To install an app from a manifest on your computer
#      scoop install \path\to\app.json
#
# Options:
#   -g, --global              Install the app globally
#   -i, --independent         Don't install dependencies automatically
#   -k, --no-cache            Don't use the download cache
#   -s, --skip                Skip hash validation (use with caution!)
#   -a, --arch <32bit|64bit>  Use the specified architecture, if the app supports it

# ────────────────────────────────────────────────────────────────────────────────
# powershell -executionpolicy bypass -File wsl-up.ps1
# pwsh -executionpolicy bypass -File wsl-up.ps1
#
# ────────────────────────────────────────────────────────── I ──────────
#   :::::: F U N C T I O N S : :  :   :    :     :        :          :
# ────────────────────────────────────────────────────────────────────
#
#
# ─── BASE ───────────────────────────────────────────────────────────────────────
#
function abort($msg, [int] $exit_code = 1) { 
    write-host $msg -f red
    exit $exit_code
  }
  function error($msg) { 
    write-host "[ERROR] $msg" -f darkred 
  }
  function warn($msg) {
    write-host "[WARN]  $msg" -f darkyellow 
  }
  function info($msg) {  
    write-host "[INFO]  $msg" -f darkcyan 
  }
  function debug($msg) {  
    write-host "[DEBUG]  $msg" -f darkgray 
  }
  function success($msg) { 
    write-host  "[DONE] $msg" -f darkgreen 
  }
  function pwd($path) {
    "$($myinvocation.psscriptroot)\$path" 
  }
  #
  # ─── USAGE HELPER METHODS ───────────────────────────────────────────────────────
  #
  
  function usage($text) {
    $text | Select-String '(?m)^# Usage: ([^\n]*)$' | ForEach-Object { "Usage: " + $_.matches[0].groups[1].value }
  }
  
  function summary($text) {
    $text | Select-String '(?m)^# Summary: ([^\n]*)$' | ForEach-Object { $_.matches[0].groups[1].value }
  }
  
  function help($text) {
    $help_lines = $text | Select-String '(?ms)^# Help:(.(?!^[^#]))*' | ForEach-Object { $_.matches[0].value; }
    $help_lines -replace '(?ms)^#\s?(Help: )?', ''
  }
  
  function my_usage {
    usage (Get-Content $myInvocation.PSCommandPath -raw)
  }
  function my_summary {
    summary (Get-Content $myInvocation.PSCommandPath -raw)
  }
  function my_help {
    help (Get-Content $myInvocation.PSCommandPath -raw)
  }
  
  #
  # ─── AUX FUNCS ──────────────────────────────────────────────────────────────────
  #
  function is_admin {
    $admin = [security.principal.windowsbuiltinrole]::administrator
    $id = [security.principal.windowsidentity]::getcurrent()
    ([security.principal.windowsprincipal]($id)).isinrole($admin)
  }
  Function WaitForKey {
    Write-Host
    Write-Host "Press any key to restart..." -ForegroundColor Black -BackgroundColor White
    [Console]::ReadKey($true) | Out-Null
  }
  Function Restart {
    info "Restarting..."
    Restart-Computer
  }
  function pwd($path) {
    "$($myinvocation.psscriptroot)\$path" 
  } 
  function Safe-Set-ItemProperty($Path, $Name, $Type, $Value) {
    try {
      debug "setting path $Path with name $Name , type $Type and value $Value"
      Set-ItemProperty -Path "$path" -Name "$Name" -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    }
    catch {
      warn "could not set path $Path with name $Name , type $Type and value $Value"
    }
  }
  function Safe-Remove-ItemProperty($Path, $Name, $Type, $Value) {
    try {
      debug "removing item property $Name of $Path"
      Remove-ItemProperty -Path "$path" -Name "$Name" -ErrorAction Stop | Out-Null
    }
    catch {
      warn "could not removing item property $Name of $Path"
    }
  }
  function Safe-Uninstall($app) {
    try {
      info "uninstalling $app"
      Get-AppxPackage -all "$app" | Remove-AppxPackage -AllUsers
      success "uninstalling $app"
    }
    catch {
      warn "uninstalling $app failed. possible cause is that $app was not installed at the time of executing $script_name script."
    }
  }
  # [ NOTE ] =>
  # - https://github.com/lukesampson/scoop/blob/master/lib/getopt.ps1
  function getopt($argv, $shortopts, $longopts) {
    $opts = @{}; $rem = @()
  
    function err($msg) {
      $opts, $rem, $msg
    }
  
    function regex_escape($str) {
      return [regex]::escape($str)
    }
  
    # ensure these are arrays
    $argv = @($argv)
    $longopts = @($longopts)
  
    for ($i = 0; $i -lt $argv.length; $i++) {
      $arg = $argv[$i]
      if ($null -eq $arg) { continue }
      # don't try to parse array arguments
      if ($arg -is [array]) { $rem += , $arg; continue }
      if ($arg -is [int]) { $rem += $arg; continue }
      if ($arg -is [decimal]) { $rem += $arg; continue }
  
      if ($arg.startswith('--')) {
        $name = $arg.substring(2)
  
        $longopt = $longopts | Where-Object { $_ -match "^$name=?$" }
  
        if ($longopt) {
          if ($longopt.endswith('=')) {
            # requires arg
            if ($i -eq $argv.length - 1) {
              return err "Option --$name requires an argument."
            }
            $opts.$name = $argv[++$i]
          }
          else {
            $opts.$name = $true
          }
        }
        else {
          return err "Option --$name not recognized."
        }
      }
      elseif ($arg.startswith('-') -and $arg -ne '-') {
        for ($j = 1; $j -lt $arg.length; $j++) {
          $letter = $arg[$j].tostring()
  
          if ($shortopts -match "$(regex_escape $letter)`:?") {
            $shortopt = $matches[0]
            if ($shortopt[1] -eq ':') {
              if ($j -ne $arg.length - 1 -or $i -eq $argv.length - 1) {
                return err "Option -$letter requires an argument."
              }
              $opts.$letter = $argv[++$i]
            }
            else {
              $opts.$letter = $true
            }
          }
          else {
            
            return err "Option -$letter not recognized."
          }
        }
      }
      else {
        $rem += $arg
      }
    }
    $opts, $rem
  }
  #
  # ──────────────────────────────────────────────────────────────── I ──────────
  #   :::::: S C R I P T   S T A R T : :  :   :    :     :        :          :
  # ──────────────────────────────────────────────────────────────────────────
  #
  $opt, $parsed_args, $err = getopt $args 'gfiksa:' 'global', 'force', 'independent', 'no-cache', 'skip','help', 'arch='
  if ($err) { "scoop install: $err";my_summary; exit 1 }
  if (!$parsed_args) { error '<app> missing'; my_usage;my_summary;my_help; exit 1 }
  $global = $opt.g -or $opt.global
  $check_hash = !($opt.s -or $opt.skip)
  $independent = $opt.i -or $opt.independent
  $use_cache = !($opt.k -or $opt.'no-cache')
  $architecture = "default_architecture"
  try {
      $architecture =  ($opt.a + $opt.arch)
      info "$architecture"
  } catch {
      abort "ERROR: $_"
  }
  
  
  if ($global -and !(is_admin)) {
      abort 'ERROR: you need admin rights to install global apps'
  }
  $suggested = @{ };
  $parsed_args | ForEach-Object { info "$_ $architecture $global $suggested $use_cache $check_hash" }
  exit 0