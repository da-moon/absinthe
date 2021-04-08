# [ NOTE ] => 
# - https://stackoverflow.com/a/21422517
function native_download([string]$url, [string] $targetFile) {
  $dir = Split-Path -parent $targetFile
  if (-not(Test-Path -Path $dir -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop
  }

  $uri = New-Object "System.Uri" "$url"
  $request = [System.Net.HttpWebRequest]::Create($uri)
  $request.set_Timeout(15000)
  $response = $request.GetResponse()
  $totalLength = [System.Math]::Floor($response.get_ContentLength() / 1024)
  $responseStream = $response.GetResponseStream()
  $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
  $buffer = new-object byte[] 10KB
  $count = $responseStream.Read($buffer, 0, $buffer.length)
  $downloadedBytes = $count
  while ($count -gt 0) {
    $targetStream.Write($buffer, 0, $count)
    $count = $responseStream.Read($buffer, 0, $buffer.length)
    $downloadedBytes = $downloadedBytes + $count
    Write-Progress -activity "Downloading file '$($url.split('/') | Select -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes / 1024)) / $totalLength) * 100)
  }
  Write-Progress -activity "Finished downloading file '$($url.split('/') | Select -Last 1)'"
  $targetStream.Flush()
  $targetStream.Close()
  $targetStream.Dispose()
  $responseStream.Dispose()
}
function aria2_download([string]$url, [string] $targetFile) {
  if(-not (test_command "aria2c") ){
    throw [System.ArgumentException] "'aria2c' was not found in PATH"
  }
  # [ NOTE ] => ensuring parent exists.
  $dir = Split-Path -parent $targetFile
  if (-not(Test-Path -Path $dir -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop
  }
  $file = Split-Path "$targetFile" -Leaf
  aria2c -k 1M -c -j16 -x16 --dir="$dir" --out="$file" "$url"
}
function download([string]$url, [string] $targetFile) {
  if (test_command "aria2c") {
    aria2_download "$url" "$targetFile"
  }
  else {
    native_download "$url" "$targetFile"
  }
}
