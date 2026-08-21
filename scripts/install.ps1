<#
PowerShell install script for Windows.
- Downloads the latest mimir release asset for Windows + arch from GitHub,
- extracts to temp, copies mimir.exe directly into %USERPROFILE%\.mimir\bin,
- ensures the install dir is on the user PATH,
- cleans up.

Usage: Run in PowerShell (may need to set ExecutionPolicy for the session):
  .\install-powershell.ps1
#>

param(
    [string]$Repo = "rivethorn/mimir"
)

$ErrorActionPreference = "Stop"
$temp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("mimir-install-" + [guid]::NewGuid().ToString())) -Force
try
{
    $arch = "x64"
    $osPat = "windows"
    Write-Output "Detected arch: $arch"

    $api = "https://api.github.com/repos/$Repo/releases/latest"
    Write-Output "Querying $api for mimir Windows/$arch asset..."
    $json = Invoke-RestMethod -Uri $api -UseBasicParsing
    $asset = $json.assets | Where-Object { $_.browser_download_url -match $osPat -and $_.browser_download_url -match $arch } | Select-Object -First 1
    if (-not $asset)
    { Write-Error "No asset found for Windows/$arch"; exit 1
    }

    $url = $asset.browser_download_url
    $dest = Join-Path $temp "artifact.zip"
    Write-Output "Downloading $url..."
    Invoke-WebRequest -Uri $url -OutFile $dest

    Expand-Archive -Path $dest -DestinationPath (Join-Path $temp "extracted") -Force

    $mimir = Get-ChildItem -Path (Join-Path $temp "extracted") -Recurse -Filter "mimir.exe" -File | Select-Object -First 1
    if (-not $mimir)
    { Write-Error "mimir.exe not found in archive"; exit 1
    }

    # Place the downloaded binary directly at the destination (no bootstrap)
    $target = Join-Path $env:LOCALAPPDATA ".mimir\bin"
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -Force $mimir.FullName (Join-Path $target "mimir.exe")
    Write-Output "Installed mimir to $target\mimir.exe"

    # Add $target to the user PATH (case-insensitive, no duplicates)
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()
    if (-not [string]::IsNullOrEmpty($userPath))
    { $parts = @($userPath -split ";") | Where-Object { $_ -ne "" }
    }

    if ($parts -inotcontains $target)
    {
        $parts += $target
        [Environment]::SetEnvironmentVariable("Path", $parts -join ";", "User")
        $env:PATH = "$target;$env:PATH"
        Write-Output "Added $target to PATH. Restart terminals/apps to pick up."
    } else
    {
        Write-Output "$target is already on PATH."
    }

    Write-Output "Install complete."
} finally
{
    Remove-Item -Recurse -Force $temp
}
