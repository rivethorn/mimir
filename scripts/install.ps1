<#
PowerShell install script for Windows.
- Downloads the latest mimir release asset for Windows + arch from GitHub,
- extracts to temp, runs mimir.exe install github.com/rivethorn/mimir,
- ensures %USERPROFILE%\.mimir\bin is in the user PATH,
- cleans up.

Usage: Run in PowerShell (may need to set ExecutionPolicy for the session):
  .\install-powershell.ps1
#>

param(
  [string]$Repo = "rivethorn/mimir"
)

$ErrorActionPreference = "Stop"
$temp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("mimir-install-" + [guid]::NewGuid().ToString())) -Force
try {
  $arch = if ($env:PROCESSOR_ARCHITECTURE -match "ARM") { "arm64" } else { "x64" }
  $osPat = "windows"
  Write-Output "Detected arch: $arch"

  $api = "https://api.github.com/repos/$Repo/releases/latest"
  Write-Output "Querying $api for mimir Windows/$arch asset..."
  $json = Invoke-RestMethod -Uri $api -UseBasicParsing
  $asset = $json.assets | Where-Object { $_.browser_download_url -match $osPat -and $_.browser_download_url -match $arch } | Select-Object -First 1
  if (-not $asset) { Write-Error "No asset found for Windows/$arch"; exit 1 }

  $url = $asset.browser_download_url
  $dest = Join-Path $temp "artifact.zip"
  Write-Output "Downloading $url..."
  Invoke-WebRequest -Uri $url -OutFile $dest

  Expand-Archive -Path $dest -DestinationPath (Join-Path $temp "extracted") -Force

  $mimir = Get-ChildItem -Path (Join-Path $temp "extracted") -Recurse -Filter "mimir.exe" -File | Select-Object -First 1
  if (-not $mimir) { Write-Error "mimir.exe not found in archive"; exit 1 }

  & $mimir.FullName install github.com/rivethorn/mimir

  $target = Join-Path $env:USERPROFILE ".mimir\bin"
  if (-not (Test-Path $target)) { New-Item -ItemType Directory -Force -Path $target | Out-Null }

  $current = [Environment]::GetEnvironmentVariable("Path","User")
  if ($current -notlike "*$target*") {
    $new = if ([string]::IsNullOrEmpty($current)) { $target } else { "$current;$target" }
    [Environment]::SetEnvironmentVariable("Path",$new,"User")
    Write-Output "Added $target to user PATH. Restart terminals/apps to pick up."
  } else {
    Write-Output "$target already in user PATH."
  }

  # Add to PowerShell profile for immediate sessions
  $profileFile = $PROFILE.CurrentUserAllHosts
  if (-not (Test-Path $profileFile)) { New-Item -ItemType File -Force -Path $profileFile | Out-Null }
  $line = "if (-not (`$env:PATH -like '*$target*')) { `$env:PATH = `"$target;`$env:PATH`" }"
  if (-not (Select-String -Path $profileFile -Pattern [regex]::Escape($line) -Quiet)) {
    Add-Content -Path $profileFile -Value $line
  }

  Write-Output "Bootstrap install complete."
} finally {
  Remove-Item -Recurse -Force $temp
}
