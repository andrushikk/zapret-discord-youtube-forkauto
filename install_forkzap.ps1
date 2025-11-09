param(
    [string]$Profile = "general"   # e.g. ALT2, ALT6, etc.
)

$ErrorActionPreference = "Stop"

$owner = "andrushikk"
$repo = "zapret-discord-youtube-forkauto"
$assetName = "forkzap.zip"

Write-Host "[*] Getting latest release info..."

try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/latest" -Headers @{
        "User-Agent" = "forkzap-installer"
    }
}
catch {
    Write-Error "[X] Failed to get release info: $($_.Exception.Message)"
    exit 1
}

$asset = $release.assets |
    Where-Object { $_.name -eq $assetName } |
    Select-Object -First 1

if (-not $asset) {
    Write-Error "[X] Asset $assetName not found in latest release."
    exit 1
}

$downloadUrl = $asset.browser_download_url
Write-Host ("[*] Found {0}: {1}" -f $assetName, $downloadUrl)

$targetRoot = "D:\forkzap"

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

$runBat = Get-ChildItem -Path $targetRoot -Recurse -Filter "*$Profile*.bat" -ErrorAction SilentlyContinue |
          Select-Object -First 1

if ($runBat) {
    Write-Host "[*] Found bat: $($runBat.FullName)"
    Start-Process -FilePath $runBat.FullName -Verb RunAs
}
else {
    Write-Host "[i] No .bat found for profile '$Profile'."
    Write-Host "Available bat files:"
    Get-ChildItem -Path $targetRoot -Recurse -Filter "*.bat" | ForEach-Object {
        Write-Host " - $($_.FullName)"
    }
}
