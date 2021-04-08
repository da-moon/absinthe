#Requires -Version 5

#
# ────────────────────────────────────────────────────────── I ──────────
#   :::::: F U N C T I O N S : :  :   :    :     :        :          :
# ────────────────────────────────────────────────────────────────────
#

function is_admin {
    $admin = [security.principal.windowsbuiltinrole]::administrator
    $id = [security.principal.windowsidentity]::getcurrent()
    ([security.principal.windowsprincipal]($id)).isinrole($admin)
}

function dl($url,$to) {
    $wc = New-Object Net.Webclient
    $wc.headers.add('Referer', (strip_filename $url))
    $wc.downloadFile($url,$to)
}



function fname($path) { split-path $path -leaf }
function strip_filename($path) { $path -replace [regex]::escape((fname $path)) }
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
#
# ─── FILE UTILS ─────────────────────────────────────────────────────────────────
#

    
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

#
# ─── ALIASES ────────────────────────────────────────────────────────────────────
#
function reset_alias($name, $value) {
    if($existing = get-alias $name -ea ignore | Where-Object { $_.options -match 'readonly' }) {
        if($existing.definition -ne $value) {
            Write-Host "Alias $name is read-only; can't reset it." -f darkyellow
        }
        return # already set
    }
    if($value -is [scriptblock]) {
        if(!(Test-Path -path "function:script:$name")) {
            New-Item -path function: -name "script:$name" -value $value | out-null
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
        'echo' = 'Write-Output'
        'gc' = 'get-content'
        'gci' = 'get-childitem'
        'gcm' = 'get-command'
        'gm' = 'get-member'
        'iex' = 'invoke-expression'
        'ls' = 'get-childitem'
        'mkdir' = { New-Item -type directory @args }
        'mv' = 'move-item'
        'rm' = 'remove-item'
        'sc' = 'set-content'
        'select' = 'select-object'
        'sls' = 'select-string'
    }

    # [ NOTE ] => set default aliases
    $default_aliases.keys | ForEach-Object { reset_alias $_ $default_aliases[$_] }
}

#
# ────────────────────────────────────────────────────────────────────────────────
function Optimize-SecurityProtocol {
    $isNewerNetFramework = ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -contains 'SystemDefault')
    $isSystemDefault = ([System.Net.ServicePointManager]::SecurityProtocol.Equals([System.Net.SecurityProtocolType]::SystemDefault))
    if (!($isNewerNetFramework -and $isSystemDefault)) {
        [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192
    }
}
# ────────────────────────────────────────────────────────────────────────────────
function test_command([Parameter(Mandatory)][string]$command) {
    return [bool](Get-Command $command -ErrorAction Ignore)
}
#
# ────────────────────────────────────────────────────────────────────── I ──────────
#   :::::: E X E C U T I O N   S T A R T : :  :   :    :     :        :          :
# ────────────────────────────────────────────────────────────────────────────────
#




Optimize-SecurityProtocol
$wsl_up_dir = "$env:USERPROFILE\.wsl-up"