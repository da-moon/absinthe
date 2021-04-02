function ensure_distro($distro_opt) {
    if(!$distro_opt) {
        return 'alpine'
    }
    switch($distro_opt) {
      { @('alpine')  -contains $_ } 
      { 
        return $_
      }
    default { 
      throw [System.ArgumentException] "Invalid distro: '$distro_opt'"
      }
    }
}