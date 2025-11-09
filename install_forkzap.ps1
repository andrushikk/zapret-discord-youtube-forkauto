param(
    [string]$Profile = "general"   # e.g. ALT2, ALT6, etc.
)

$ErrorActionPreference = "Stop"

$owner     = "andrushikk"
$repo      = "zapret-discord-youtube-forkauto"
$assetName = "forkzap.zip"

Write-Host "[*] Getting latest release info..."

try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/latest" -Headers @{
        "User-Agent" = "forkzap-installer"
    }
}
catch {
    Write-Error "[X] Failed to get release info: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    exit 1
}

$asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1

if (-not $asset) {
    Write-Error "[X] Asset $assetName not found in latest release."
    Read-Host "Press Enter to exit"
    exit 1
}

$downloadUrl = $asset.browser_download_url
Write-Host ("[*] Found {0}: {1}" -f $assetName, $downloadUrl)

# Target directory
$targetRoot = "D:\forkzap"

# if (-not (Test-Path "D:\")) {
#     Write-Error "[!] Drive D: not found. Change targetRoot in script or create drive D."
#     Read-Host "Press Enter to exit"
#     exit 1
# }

if (-not (Test-Path $targetRoot)) {
    New-Item -ItemType Directory -Path $targetRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP $assetName

Write-Host "[*] Downloading zip..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $tmpZip

Write-Host "[*] Extracting to $targetRoot ..."
Expand-Archive -LiteralPath $tmpZip -DestinationPath $targetRoot -Force

Remove-Item $tmpZip -Force

Write-Host "[✔] Done. Files extracted to: $targetRoot"

# Find bat by profile: ALT6 -> matches "general (ALT6).bat"
$runBat = Get-ChildItem -Path $targetRoot -Recurse -Filter "*$Profile*.bat" -ErrorAction SilentlyContinue |
          Select-Object -First 1

if ($runBat) {
    Write-Host "[*] Found bat: $($runBat.FullName)"
    Read-Host "Press Enter to run it as admin..."
    Start-Process -FilePath $runBat.FullName -Verb RunAs
}
else {
    Write-Host "[i] No .bat found for profile '$Profile'."
    Write-Host "Available bat files:"
    Get-ChildItem -Path $targetRoot -Recurse -Filter "*.bat" | ForEach-Object {
        Write-Host " - $($_.FullName)"
    }
    Read-Host "Press Enter to exit"
}

# Example:
# powershell -NoP -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://raw.githubusercontent.com/andrushikk/zapret-discord-youtube-forkauto/main/install_forkzap.ps1' -OutFile $env:TEMP\install_forkzap.ps1; & $env:TEMP\install_forkzap.ps1 -Profile 'ALT6'"
