function ensure_distro($distro_opt) {
  if (!$distro_opt) {
    return 'arch'
  }
  switch ($distro_opt) {
    { @('alpine', 'arch') -contains $_ } {
      return $_
    }
    default {
      throw [System.ArgumentException] "Invalid distro: '$distro_opt'"
    }
  }
}
function filesystem_url( [string] $distro ){
  try {
    $null=ensure_distro($distro)
  }
  catch {
    throw $_.Exception.Message
  }
  $alpine_base_url="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases"
  $architecture = $Env:PROCESSOR_ARCHITECTURE.ToLower()
  switch ($architecture) {
    "amd64" {
      switch ($distro) {
        "arch" {
          return "https://archive.archlinux.org/iso/$(Get-Date -Format 'yyyy.MM').01/archlinux-bootstrap-$(Get-Date -Format 'yyyy.MM').01-x86_64.tar.gz" 
        }
        "alpine" {
          # [ NOTE ] => ensuring powershell YAML module is installed
          if (-not(Get-Module -ListAvailable -Name powershell-yaml)) {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force
          }
          Import-Module powershell-yaml
          $yml_url = "$alpine_base_url/x86_64/latest-releases.yaml"
          $file = (ConvertFrom-Yaml (new-object net.webclient).downloadstring($yml_url)).ToArray() | `
          Where-Object { $_.flavor -eq 'alpine-minirootfs' } | `
          select-object @{
            label      = 'file'
            expression = { $_.file }
          } | Select-Object -ExpandProperty file
          return "$alpine_base_url/x86_64/$file"
        }
        default {
          throw [System.ArgumentException] "Could not locate $architecture file system: '$distro'"
        }
      }
    }
    "arm64" {
      switch ($distro) {
        "arch" { return "http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz" }
        "alpine" {
          # [ NOTE ] => ensuring powershell YAML module is installed
          if (-not(Get-Module -ListAvailable -Name powershell-yaml)) {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force
          }
          $yml_url = "$alpine_base_url/aarch64/latest-releases.yaml"
          # [ NOTE ] => ensuring powershell YAML module is installed
          if (-not(Get-Module -ListAvailable -Name powershell-yaml)) {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force
          }
          Import-Module powershell-yaml
          $yml_url = "$alpine_base_url/x86_64/latest-releases.yaml"
          $file = (ConvertFrom-Yaml (new-object net.webclient).downloadstring($yml_url)).ToArray() | `
            Where-Object { $_.flavor -eq 'alpine-minirootfs' } | `
            select-object @{
            label      = 'file'
            expression = { $_.file }
          } | Select-Object -ExpandProperty file
          return "$alpine_base_url/aarch64/$file"
          }
        default {
          throw [System.ArgumentException] "Could not locate $architecture file system: '$distro'"
        }

      }
    }
    "x86" {
      switch ($distro) {
        "alpine" {
          # [ NOTE ] => ensuring powershell YAML module is installed
          if (-not(Get-Module -ListAvailable -Name powershell-yaml)) {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force
          }
          $yml_url = "$alpine_base_url/x86/latest-releases.yaml"
          $file = (ConvertFrom-Yaml (new-object net.webclient).downloadstring($yml_url)).ToArray() | `
            Where-Object { $_.flavor -eq 'alpine-minirootfs' } | `
            select-object @{
            label      = 'file'
            expression = { $_.file }
          } | Select-Object -ExpandProperty file
          return "$alpine_base_url/x86/$file"
        }
        default {
          throw [System.ArgumentException] "Could not locate $architecture file system: '$distro'"
        }
      }
    }
    default {
      throw [System.ArgumentException] "Invalid architecture: '$architecture'"
    }
  }

}