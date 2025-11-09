param(
    [string]$Profile = "general"   # Например: ALT2, ALT3 и т.п.
)

$ErrorActionPreference = "Stop"

$owner     = "andrushikk"
$repo      = "zapret-discord-youtube-forkauto"
$assetName = "forkzap.zip"

Write-Host "[*] Получаю информацию о последнем релизе..."

try {
    $release = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$owner/$repo/releases/latest" `
        -Headers @{ "User-Agent" = "forkzap-installer" }
}
catch {
    Write-Error "[X] Не удалось получить данные о релизе с GitHub: $($_.Exception.Message)"
    exit 1
}

$asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1

if (-not $asset) {
    Write-Error "[X] В последнем релизе не найден файл $assetName."
    exit 1
}

$downloadUrl = $asset.browser_download_url
Write-Host "[*] Найден $assetName: $downloadUrl"

# Куда ставим
$targetRoot = "D:\forkzap"
if (-not (Test-Path "D:\")) {
    Write-Error "[!] Диск D: не найден."
    exit 1
}

if (-not (Test-Path $targetRoot)) {
    New-Item -ItemType Directory -Path $targetRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP $assetName

Write-Host "[*] Скачиваю архив..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $tmpZip

Write-Host "[*] Распаковываю в $targetRoot ..."
Expand-Archive -LiteralPath $tmpZip -DestinationPath $targetRoot -Force

Remove-Item $tmpZip -Force

Write-Host "[✔] Готово. Файлы распакованы в: $targetRoot"

# Ищем батник по профилю.
# Например, Profile = ALT2 найдёт файл, содержащий "ALT2" в имени:
# "general (ALT2).bat" → матчится.
$runBat = Get-ChildItem -Path $targetRoot -Recurse -Filter "*$Profile*.bat" -ErrorAction SilentlyContinue |
          Select-Object -First 1

if ($runBat) {
    Write-Host "[*] Запускаю $($runBat.FullName) c правами администратора..."
    Start-Process -FilePath $runBat.FullName -Verb RunAs
} else {
    Write-Host "[i] Не найден .bat для профиля '$Profile'."
    Write-Host "Доступные батники:"
    Get-ChildItem -Path $targetRoot -Recurse -Filter "*.bat" | ForEach-Object {
        Write-Host " - $($_.FullName)"
    }
}
