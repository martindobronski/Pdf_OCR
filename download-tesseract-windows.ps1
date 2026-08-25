# download-tesseract-windows.ps1
# Downloads Tesseract OCR Windows binaries for bundling
# Automatically downloads portable 7-Zip if not installed

$ErrorActionPreference = "Stop"
$TESSERACT_VERSION = "5.4.0.20240606"
$DOWNLOAD_URL = "https://github.com/UB-Mannheim/tesseract/releases/download/v5.4.0.20240606/tesseract-ocr-w64-setup-5.4.0.20240606.exe"
$TARGET_DIR = "src\main\resources\native\windows-x64"
$TEMP_DIR = "$env:TEMP\tesseract_ocr_build"

Write-Host "=== Tesseract OCR Windows Download ===" -ForegroundColor Cyan
Write-Host "Version: $TESSERACT_VERSION"
Write-Host ""

# =========================================================================
# SCHRITT 1: Verzeichnisse vorab bereinigen und neu erstellen
# =========================================================================
if (-not (Test-Path $TARGET_DIR)) {
    New-Item -ItemType Directory -Path $TARGET_DIR -Force | Out-Null
}
if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# =========================================================================
# SCHRITT 2: 7-Zip lokalisieren oder portabel herunterladen
# =========================================================================
$7z = $null
$7zPaths = @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe",
    "${env:ProgramFiles}\7-Zip\7z.exe"
)

# Prüfen, ob 7-Zip bereits lokal installiert ist
foreach ($p in $7zPaths) {
    if (Test-Path $p) {
        $7z = $p
        break
    }
}

# Falls nicht gefunden, Installation via winget versuchen
if (-not $7z) {
    Write-Host "7-Zip not found. Trying to install via winget..." -ForegroundColor Yellow
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        & winget install --id 7zip.7zip --accept-source-agreements --accept-package-agreements 2>$null
        foreach ($p in $7zPaths) {
            if (Test-Path $p) {
                $7z = $p
                break
            }
        }
    }
}

# Portables 7-Zip als finaler Fallback herunterladen
if (-not $7z) {
    Write-Host "Downloading portable 7-Zip..." -ForegroundColor Yellow
    $7zPortableDir = "$TEMP_DIR\7zip"
    $7zPortableExe = "$7zPortableDir\7za.exe"
    
    New-Item -ItemType Directory -Path $7zPortableDir -Force | Out-Null
    $7zZipUrl = "https://www.7-zip.org/a/7za920.zip"
    $7zZipPath = "$TEMP_DIR\7za.zip"
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $7zZipUrl -OutFile $7zZipPath -UseBasicParsing
        
        # Verwende das native Expand-Archive (zuverlässiger in modernen PS-Versionen)
        Expand-Archive -Path $7zZipPath -DestinationPath $7zPortableDir -Force
        
        if (Test-Path $7zPortableExe) {
            $7z = $7zPortableExe
            Write-Host "Portable 7-Zip ready: $7z" -ForegroundColor Green
        } else {
            throw "7za.exe konnte im ZIP-Archiv nicht gefunden werden."
        }
    } catch {
        Write-Host "ERROR: Could not get portable 7-Zip." -ForegroundColor Red
        Write-Host "Please install manually: https://7-zip.org/download.html"
        exit 1
    }
}

Write-Host "Using 7-Zip: $7z" -ForegroundColor Green

# =========================================================================
# SCHRITT 3: Tesseract Installer herunterladen
# =========================================================================
$installerPath = "$TEMP_DIR\tesseract-setup.exe"
Write-Host ""
Write-Host "Downloading Tesseract $TESSERACT_VERSION..." -ForegroundColor Yellow

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $installerPath -UseBasicParsing
    Write-Host "Download complete ($([math]::Round((Get-Item $installerPath).Length/1MB)) MB)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Download failed." -ForegroundColor Red
    Write-Host "URL: $DOWNLOAD_URL"
    exit 1
}

# =========================================================================
# SCHRITT 4: Installer extrahieren
# =========================================================================
Write-Host ""
Write-Host "Extracting installer with 7-Zip..." -ForegroundColor Yellow
$extractDir = "$TEMP_DIR\extracted"
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

& "$7z" x "$installerPath" -o"$extractDir" -y 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: 7-Zip extraction failed with code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# Prüfen auf verschachtelte Installer (NSIS Wrapper)
$nested = Get-ChildItem -Path $extractDir -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "*tesseract*" -and $_.FullName -ne $installerPath }
if ($nested) {
    Write-Host "Found nested installer, extracting again..." -ForegroundColor Yellow
    $nestedExtract = "$TEMP_DIR\nested"
    New-Item -ItemType Directory -Path $nestedExtract -Force | Out-Null
    & "$7z" x $nested[0].FullName -o"$nestedExtract" -y 2>&1 | Out-Null
}

# =========================================================================
# SCHRITT 5: DLLs suchen und ins Maven-Ressourcen-Target kopieren
# =========================================================================
Write-Host ""
Write-Host "Searching for DLLs..." -ForegroundColor Yellow
$dllFiles = Get-ChildItem -Path $TEMP_DIR -Filter "*.dll" -Recurse -ErrorAction SilentlyContinue
Write-Host "Found $($dllFiles.Count) DLL files total" -ForegroundColor Cyan

if ($dllFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "Directory structure:" -ForegroundColor Yellow
    Get-ChildItem -Path $TEMP_DIR -Recurse -Directory | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor DarkGray
    }
    Get-ChildItem -Path $TEMP_DIR -Recurse -File | Select-Object -First 30 | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Copying DLLs to $TARGET_DIR..." -ForegroundColor Yellow
$copiedCount = 0
foreach ($dll in $dllFiles) {
    $target = Join-Path $TARGET_DIR $dll.Name
    if (-not (Test-Path $target)) {
        Copy-Item -Path $dll.FullName -Destination $TARGET_DIR -Force
        Write-Host "  Copied: $($dll.Name) ($([math]::Round($dll.Length/1KB)) KB)" -ForegroundColor Green
        $copiedCount++
    }
}

# =========================================================================
# SCHRITT 6: Bereinigung (nur den temporären Ordner ohne das portable 7zip)
# =========================================================================
Write-Host ""
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
# Behalte die portable 7-Zip EXE unberührt, falls Fehler auftreten, aber lösche den Rest
Get-ChildItem -Path $TEMP_DIR | Where-Object { $_.Name -ne "7zip" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# =========================================================================
# SCHRITT 7: Zusammenfassung
# =========================================================================
Write-Host ""
if ($copiedCount -gt 0) {
    Write-Host "=== Done! ===" -ForegroundColor Green
    Write-Host "Copied $copiedCount DLLs to $TARGET_DIR"
    Write-Host ""
    Write-Host "Files:" -ForegroundColor Cyan
    Get-ChildItem -Path $TARGET_DIR -Filter "*.dll" | Sort-Object Name | ForEach-Object {
        Write-Host "  $($_.Name) ($([math]::Round($_.Length/1KB)) KB)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. git add $TARGET_DIR"
    Write-Host "  2. git commit -m 'Add Windows Tesseract DLLs'"
    Write-Host "  3. mvn clean package"
} else {
    Write-Host "=== ERROR: No DLLs found! ===" -ForegroundColor Red
    Write-Host "The installer might need to be extracted differently."
    Write-Host "Try installing Tesseract manually and copy DLLs from:"
    Write-Host "  C:\Program Files\Tesseract-OCR\"
}
