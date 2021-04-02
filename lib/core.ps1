function Optimize-SecurityProtocol {
    # .NET Framework 4.7+ has a default security protocol called 'SystemDefault',
    # which allows the operating system to choose the best protocol to use.
    # If SecurityProtocolType contains 'SystemDefault' (means .NET4.7+ detected)
    # and the value of SecurityProtocol is 'SystemDefault', just do nothing on SecurityProtocol,
    # 'SystemDefault' will use TLS 1.2 if the webrequest requires.
    $isNewerNetFramework = ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -contains 'SystemDefault')
    $isSystemDefault = ([System.Net.ServicePointManager]::SecurityProtocol.Equals([System.Net.SecurityProtocolType]::SystemDefault))

    # If not, change it to support TLS 1.2
    if (!($isNewerNetFramework -and $isSystemDefault)) {
        # Set to TLS 1.2 (3072), then TLS 1.1 (768), and TLS 1.0 (192). Ssl3 has been superseded,
        # https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netframework-4.5
        [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192
    }
}

function Show-DeprecatedWarning {
    <#
    .SYNOPSIS
        Print deprecated warning for functions, which will be deleted in near future.
    .PARAMETER Invocation
        Invocation to identify location of line.
        Just pass $MyInvocation.
    .PARAMETER New
        New command name.
    #>
    param($Invocation, [String] $New)

    warn ('"{0}" will be deprecated. Please change your code/manifest to use "{1}"' -f $Invocation.MyCommand.Name, $New)
    Write-Host "      -> $($Invocation.PSCommandPath):$($Invocation.ScriptLineNumber):$($Invocation.OffsetInLine)" -ForegroundColor DarkGray
}



# helper functions
function coalesce($a, $b) { if($a) { return $a } $b }

function format($str, $hash) {
    $hash.keys | ForEach-Object { set-variable $_ $hash[$_] }
    $executionContext.invokeCommand.expandString($str)
}
function is_admin {
    $admin = [security.principal.windowsbuiltinrole]::administrator
    $id = [security.principal.windowsidentity]::getcurrent()
    ([security.principal.windowsprincipal]($id)).isinrole($admin)
}

# messages
function abort($msg, [int] $exit_code=1) { write-host $msg -f red; exit $exit_code }
function error($msg) { write-host "ERROR $msg" -f darkred }
function warn($msg) {  write-host "WARN  $msg" -f darkyellow }
function info($msg) {  write-host "INFO  $msg" -f darkgray }
function debug($obj) {
    $prefix = "DEBUG[$(Get-Date -UFormat %s)]"
    $param = $MyInvocation.Line.Replace($MyInvocation.InvocationName, '').Trim()
    $msg = $obj | Out-String -Stream

    if($null -eq $obj -or $null -eq $msg) {
        Write-Host "$prefix $param = " -f DarkCyan -NoNewline
        Write-Host '$null' -f DarkYellow -NoNewline
        Write-Host " -> $($MyInvocation.PSCommandPath):$($MyInvocation.ScriptLineNumber):$($MyInvocation.OffsetInLine)" -f DarkGray
        return
    }

    if($msg.GetType() -eq [System.Object[]]) {
        Write-Host "$prefix $param ($($obj.GetType()))" -f DarkCyan -NoNewline
        Write-Host " -> $($MyInvocation.PSCommandPath):$($MyInvocation.ScriptLineNumber):$($MyInvocation.OffsetInLine)" -f DarkGray
        $msg | Where-Object { ![String]::IsNullOrWhiteSpace($_) } |
            Select-Object -Skip 2 | # Skip headers
            ForEach-Object {
                Write-Host "$prefix $param.$($_)" -f DarkCyan
            }
    } else {
        Write-Host "$prefix $param = $($msg.Trim())" -f DarkCyan -NoNewline
        Write-Host " -> $($MyInvocation.PSCommandPath):$($MyInvocation.ScriptLineNumber):$($MyInvocation.OffsetInLine)" -f DarkGray
    }
}
function success($msg) { write-host $msg -f darkgreen }

function filesize($length) {
    $gb = [math]::pow(2, 30)
    $mb = [math]::pow(2, 20)
    $kb = [math]::pow(2, 10)

    if($length -gt $gb) {
        "{0:n1} GB" -f ($length / $gb)
    } elseif($length -gt $mb) {
        "{0:n1} MB" -f ($length / $mb)
    } elseif($length -gt $kb) {
        "{0:n1} KB" -f ($length / $kb)
    } else {
        "$($length) B"
    }
}

# dirs
function basedir($global) { if($global) { return $globaldir } $wsl_up_dir }

# apps
function sanitary_path($path) { return [regex]::replace($path, "[/\\?:*<>|]", "") }

function file_path($app, $file) {
    Show-DeprecatedWarning $MyInvocation 'Get-AppFilePath'
    Get-AppFilePath -App $app -File $file
}

Function Test-CommandAvailable {
    param (
        [String]$Name
    )
    Return [Boolean](Get-Command $Name -ErrorAction Ignore)
}



# paths
function fname($path) { split-path $path -leaf }
function strip_ext($fname) { $fname -replace '\.[^\.]*$', '' }
function strip_filename($path) { $path -replace [regex]::escape((fname $path)) }
function strip_fragment($url) { $url -replace (new-object uri $url).fragment }

function url_filename($url) {
    (split-path $url -leaf).split('?') | Select-Object -First 1
}
# Unlike url_filename which can be tricked by appending a
# URL fragment (e.g. #/dl.7z, useful for coercing a local filename),
# this function extracts the original filename from the URL.
function url_remote_filename($url) {
    $uri = (New-Object URI $url)
    $basename = Split-Path $uri.PathAndQuery -Leaf
    If ($basename -match ".*[?=]+([\w._-]+)") {
        $basename = $matches[1]
    }
    If (($basename -notlike "*.*") -or ($basename -match "^[v.\d]+$")) {
        $basename = Split-Path $uri.AbsolutePath -Leaf
    }
    If (($basename -notlike "*.*") -and ($uri.Fragment -ne "")) {
        $basename = $uri.Fragment.Trim('/', '#')
    }
    return $basename
}

function ensure($dir) { if(!(test-path $dir)) { mkdir $dir > $null }; resolve-path $dir }
function fullpath($path) { # should be ~ rooted
    $executionContext.sessionState.path.getUnresolvedProviderPathFromPSPath($path)
}
# function relpath($path) { "$($myinvocation.psscriptroot)\$path" }
function relpath($path) { Resolve-Path -Path "$($myinvocation.psscriptroot)\$path" }

function friendly_path($path) {
    $h = (Get-PsProvider 'FileSystem').home; if(!$h.endswith('\')) { $h += '\' }
    if($h -eq '\') { return $path }
    return "$path" -replace ([regex]::escape($h)), "~\"
}
function is_local($path) {
    ($path -notmatch '^https?://') -and (test-path $path)
}

# operations

function run($exe, $arg, $msg, $continue_exit_codes) {
    Show-DeprecatedWarning $MyInvocation 'Invoke-ExternalCommand'
    Invoke-ExternalCommand -FilePath $exe -ArgumentList $arg -Activity $msg -ContinueExitCodes $continue_exit_codes
}

function Invoke-ExternalCommand {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [Alias("Path")]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,
        [Parameter(Position = 1)]
        [Alias("Args")]
        [String[]]
        $ArgumentList,
        [Parameter(ParameterSetName = "UseShellExecute")]
        [Switch]
        $RunAs,
        [Alias("Msg")]
        [String]
        $Activity,
        [Alias("cec")]
        [Hashtable]
        $ContinueExitCodes,
        [Parameter(ParameterSetName = "Default")]
        [Alias("Log")]
        [String]
        $LogPath
    )
    if ($Activity) {
        Write-Host "$Activity " -NoNewline
    }
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo.FileName = $FilePath
    $Process.StartInfo.Arguments = ($ArgumentList | Select-Object -Unique) -join ' '
    $Process.StartInfo.UseShellExecute = $false
    if ($LogPath) {
        if ($FilePath -match '(^|\W)msiexec($|\W)') {
            $Process.StartInfo.Arguments += " /lwe `"$LogPath`""
        } else {
            $Process.StartInfo.RedirectStandardOutput = $true
            $Process.StartInfo.RedirectStandardError = $true
        }
    }
    if ($RunAs) {
        $Process.StartInfo.UseShellExecute = $true
        $Process.StartInfo.Verb = 'RunAs'
    }
    try {
        $Process.Start() | Out-Null
    } catch {
        if ($Activity) {
            Write-Host "error." -ForegroundColor DarkRed
        }
        error $_.Exception.Message
        return $false
    }
    if ($LogPath -and ($FilePath -notmatch '(^|\W)msiexec($|\W)')) {
        Out-File -FilePath $LogPath -Encoding ASCII -Append -InputObject $Process.StandardOutput.ReadToEnd()
    }
    $Process.WaitForExit()
    if ($Process.ExitCode -ne 0) {
        if ($ContinueExitCodes -and ($ContinueExitCodes.ContainsKey($Process.ExitCode))) {
            if ($Activity) {
                Write-Host "done." -ForegroundColor DarkYellow
            }
            warn $ContinueExitCodes[$Process.ExitCode]
            return $true
        } else {
            if ($Activity) {
                Write-Host "error." -ForegroundColor DarkRed
            }
            error "Exit code was $($Process.ExitCode)!"
            return $false
        }
    }
    if ($Activity) {
        Write-Host "done." -ForegroundColor Green
    }
    return $true
}

function dl($url,$to) {
    $wc = New-Object Net.Webclient
    $wc.headers.add('Referer', (strip_filename $url))
    $wc.downloadFile($url,$to)
}

function env($name,$global,$val='__get') {
    $target = 'User'; if($global) {$target = 'Machine'}
    if($val -eq '__get') { [environment]::getEnvironmentVariable($name,$target) }
    else { [environment]::setEnvironmentVariable($name,$val,$target) }
}

function isFileLocked([string]$path) {
    $file = New-Object System.IO.FileInfo $path

    if ((Test-Path -Path $path) -eq $false) {
        return $false
    }

    try {
        $stream = $file.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($stream) {
            $stream.Close()
        }
        return $false
    }
    catch {
        # file is locked by a process.
        return $true
    }
}

function is_directory([String] $path) {
    return (Test-Path $path) -and (Get-Item $path) -is [System.IO.DirectoryInfo]
}

function movedir($from, $to) {
    $from = $from.trimend('\')
    $to = $to.trimend('\')

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo.FileName = 'robocopy.exe'
    $proc.StartInfo.Arguments = "`"$from`" `"$to`" /e /move"
    $proc.StartInfo.RedirectStandardOutput = $true
    $proc.StartInfo.RedirectStandardError = $true
    $proc.StartInfo.UseShellExecute = $false
    $proc.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $proc.Start()
    $out = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()

    if($proc.ExitCode -ge 8) {
        debug $out
        throw "Could not find '$(fname $from)'! (error $($proc.ExitCode))"
    }

    # wait for robocopy to terminate its threads
    1..10 | ForEach-Object {
        if (Test-Path $from) {
            Start-Sleep -Milliseconds 100
        }
    }
}


function search_in_path($target) {
    $path = (env 'PATH' $false) + ";" + (env 'PATH' $true)
    foreach($dir in $path.split(';')) {
        if(test-path "$dir\$target" -pathType leaf) {
            return "$dir\$target"
        }
    }
}

function ensure_in_path($dir, $global) {
    $path = env 'PATH' $global
    $dir = fullpath $dir
    if($path -notmatch [regex]::escape($dir)) {
        write-output "Adding $(friendly_path $dir) to $(if($global){'global'}else{'your'}) path."

        env 'PATH' $global "$dir;$path" # for future sessions...
        $env:PATH = "$dir;$env:PATH" # for this session
    }
}

function strip_path($orig_path, $dir) {
    if($null -eq $orig_path) { $orig_path = '' }
    $stripped = [string]::join(';', @( $orig_path.split(';') | Where-Object { $_ -and $_ -ne $dir } ))
    return ($stripped -ne $orig_path), $stripped
}

function add_first_in_path($dir, $global) {
    $dir = fullpath $dir

    # future sessions
    $null, $currpath = strip_path (env 'path' $global) $dir
    env 'path' $global "$dir;$currpath"

    # this session
    $null, $env:PATH = strip_path $env:PATH $dir
    $env:PATH = "$dir;$env:PATH"
}

function remove_from_path($dir, $global) {
    $dir = fullpath $dir

    # future sessions
    $was_in_path, $newpath = strip_path (env 'path' $global) $dir
    if($was_in_path) {
        Write-Output "Removing $(friendly_path $dir) from your path."
        env 'path' $global $newpath
    }

    # current session
    $was_in_path, $newpath = strip_path $env:PATH $dir
    if($was_in_path) { $env:PATH = $newpath }
}

function wraptext($text, $width) {
    if(!$width) { $width = $host.ui.rawui.buffersize.width };
    $width -= 1 # be conservative: doesn't seem to print the last char

    $text -split '\r?\n' | ForEach-Object {
        $line = ''
        $_ -split ' ' | ForEach-Object {
            if($line.length -eq 0) { $line = $_ }
            elseif($line.length + $_.length + 1 -le $width) { $line += " $_" }
            else { $lines += ,$line; $line = $_ }
        }
        $lines += ,$line
    }

    $lines -join "`n"
}

function pluralize($count, $singular, $plural) {
    if($count -eq 1) { $singular } else { $plural }
}

function reset_alias($name, $value) {
    if($existing = get-alias $name -ea ignore | Where-Object { $_.options -match 'readonly' }) {
        if($existing.definition -ne $value) {
            write-host "Alias $name is read-only; can't reset it." -f darkyellow
        }
        return # already set
    }
    if($value -is [scriptblock]) {
        if(!(test-path -path "function:script:$name")) {
            new-item -path function: -name "script:$name" -value $value | out-null
        }
        return
    }

    set-alias $name $value -scope script -option allscope
}

function reset_aliases() {
    # for aliases where there's a local function, re-alias so the function takes precedence
    $aliases = get-alias | Where-Object { $_.options -notmatch 'readonly|allscope' } | ForEach-Object { $_.name }
    get-childitem function: | ForEach-Object {
        $fn = $_.name
        if($aliases -contains $fn) {
            set-alias $fn local:$fn -scope script
        }
    }

    # for dealing with user aliases
    $default_aliases = @{
        'cp' = 'copy-item'
        'echo' = 'write-output'
        'gc' = 'get-content'
        'gci' = 'get-childitem'
        'gcm' = 'get-command'
        'gm' = 'get-member'
        'iex' = 'invoke-expression'
        'ls' = 'get-childitem'
        'mkdir' = { new-item -type directory @args }
        'mv' = 'move-item'
        'rm' = 'remove-item'
        'sc' = 'set-content'
        'select' = 'select-object'
        'sls' = 'select-string'
    }

    # set default aliases
    $default_aliases.keys | ForEach-Object { reset_alias $_ $default_aliases[$_] }
}




function substitute($entity, [Hashtable] $params, [Bool]$regexEscape = $false) {
    if ($entity -is [Array]) {
        return $entity | ForEach-Object { substitute $_ $params $regexEscape}
    } elseif ($entity -is [String]) {
        $params.GetEnumerator() | ForEach-Object {
            if($regexEscape -eq $false -or $null -eq $_.Value) {
                $entity = $entity.Replace($_.Name, $_.Value)
            } else {
                $entity = $entity.Replace($_.Name, [Regex]::Escape($_.Value))
            }
        }
        return $entity
    }
}

function format_hash([String] $hash) {
    $hash = $hash.toLower()
    switch ($hash.Length)
    {
        32 { $hash = "md5:$hash" } # md5
        40 { $hash = "sha1:$hash" } # sha1
        64 { $hash = $hash } # sha256
        128 { $hash = "sha512:$hash" } # sha512
        default { $hash = $null }
    }
    return $hash
}

function format_hash_aria2([String] $hash) {
    $hash = $hash -split ':' | Select-Object -Last 1
    switch ($hash.Length)
    {
        32 { $hash = "md5=$hash" } # md5
        40 { $hash = "sha-1=$hash" } # sha1
        64 { $hash = "sha-256=$hash" } # sha256
        128 { $hash = "sha-512=$hash" } # sha512
        default { $hash = $null }
    }
    return $hash
}

function get_hash([String] $multihash) {
    $type, $hash = $multihash -split ':'
    if(!$hash) {
        # no type specified, assume sha256
        $type, $hash = 'sha256', $multihash
    }

    if(@('md5','sha1','sha256', 'sha512') -notcontains $type) {
        return $null, "Hash type '$type' isn't supported."
    }

    return $type, $hash.ToLower()
}


##################
# Core Bootstrap #
##################

# Note: Github disabled TLS 1.0 support on 2018-02-23. Need to enable TLS 1.2
#       for all communication with api.github.com
Optimize-SecurityProtocol
$wsl_up_dir = "$env:USERPROFILE\wsl-up"

