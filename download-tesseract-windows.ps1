# download-tesseract-windows.ps1
# Downloads Tesseract OCR Windows binaries for bundling
# Uses 7-Zip to extract the NSIS installer (more reliable than silent install)
#
# Prerequisites: 7-Zip must be installed (https://7-zip.org)
#   winget install 7zip.7zip
#   or download from https://7-zip.org/download.html

$ErrorActionPreference = "Stop"

$TESSERACT_VERSION = "5.5.3.20260724"
$DOWNLOAD_URL = "https://github.com/UB-Mannheim/tesseract/releases/download/v5.5.3.20260724/tesseract-ocr-w64-setup-5.5.3.20260724.exe"
$TARGET_DIR = "src\main\resources\native\windows-x64"
$TEMP_DIR = "$env:TEMP\tesseract_ocr_build"

Write-Host "=== Tesseract OCR Windows Download ===" -ForegroundColor Cyan
Write-Host "Version: $TESSERACT_VERSION"
Write-Host ""

# Find 7-Zip
$7zPaths = @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe",
    "${env:ProgramFiles}\7-Zip\7z.exe",
    "7z.exe"
)
$7z = $null
foreach ($p in $7zPaths) {
    if (Get-Command $p -ErrorAction SilentlyContinue) {
        $7z = $p
        break
    }
}

if (-not $7z) {
    Write-Host "ERROR: 7-Zip not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install 7-Zip first:" -ForegroundColor Yellow
    Write-Host "  winget install 7zip.7zip"
    Write-Host "  or download from https://7-zip.org/download.html"
    exit 1
}

Write-Host "Using 7-Zip: $7z" -ForegroundColor Green

# Create directories
if (-not (Test-Path $TARGET_DIR)) {
    New-Item -ItemType Directory -Path $TARGET_DIR -Force | Out-Null
}
if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force
}
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Download
$installerPath = "$TEMP_DIR\tesseract-setup.exe"
Write-Host ""
Write-Host "Downloading Tesseract $TESSERACT_VERSION..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $installerPath -UseBasicParsing
    Write-Host "Download complete: $installerPath" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Download failed." -ForegroundColor Red
    Write-Host "URL: $DOWNLOAD_URL"
    exit 1
}

# Extract with 7-Zip (NSIS installers are 7z archives)
Write-Host ""
Write-Host "Extracting installer with 7-Zip..." -ForegroundColor Yellow
$extractDir = "$TEMP_DIR\extracted"
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

& "$7z" x "$installerPath" -o"$extractDir" -y
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: 7-Zip extraction failed with code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# NSIS installers have a $PLUGINSDIR with the actual files
# Search recursively for DLLs
Write-Host ""
Write-Host "Searching for DLLs in extracted files..." -ForegroundColor Yellow

$dllFiles = Get-ChildItem -Path $extractDir -Filter "*.dll" -Recurse -ErrorAction SilentlyContinue
Write-Host "Found $($dllFiles.Count) DLL files" -ForegroundColor Cyan

# DLLs we need (with common name variations)
$neededDlls = @(
    "tesseract.dll",
    "leptonica-*.dll",
    "libarchive-*.dll",
    "libpng*.dll",
    "libjpeg*.dll",
    "libtiff*.dll",
    "libwebp*.dll",
    "libwebpmux*.dll",
    "libsharpyuv*.dll",
    "libopenjp2*.dll",
    "libzstd*.dll",
    "liblzma*.dll",
    "liblz4*.dll",
    "zlib*.dll",
    "libz*.dll",
    "gcc_s_seh*.dll",
    "libwinpthread*.dll",
    "libstdc++*.dll",
    "libgomp*.dll"
)

Write-Host ""
Write-Host "Copying DLLs to $TARGET_DIR..." -ForegroundColor Yellow

$copiedCount = 0
foreach ($pattern in $neededDlls) {
    $matches = $dllFiles | Where-Object { $_.Name -like $pattern }
    foreach ($dll in $matches) {
        $target = Join-Path $TARGET_DIR $dll.Name
        if (-not (Test-Path $target)) {
            Copy-Item -Path $dll.FullName -Destination $TARGET_DIR -Force
            Write-Host "  Copied: $($dll.Name)" -ForegroundColor Green
            $copiedCount++
        }
    }
}

# Copy ALL remaining DLLs not yet copied
foreach ($dll in $dllFiles) {
    $target = Join-Path $TARGET_DIR $dll.Name
    if (-not (Test-Path $target)) {
        Copy-Item -Path $dll.FullName -Destination $TARGET_DIR -Force
        Write-Host "  Additional: $($dll.Name)" -ForegroundColor DarkGreen
        $copiedCount++
    }
}

# Cleanup
Write-Host ""
Write-Host "Cleaning up temp files..." -ForegroundColor Yellow
Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Copied $copiedCount DLLs to $TARGET_DIR"
Write-Host ""
Write-Host "Files in target directory:" -ForegroundColor Cyan
Get-ChildItem -Path $TARGET_DIR -Filter "*.dll" | Sort-Object Name | ForEach-Object {
    Write-Host "  $($_.Name) ($([math]::Round($_.Length/1KB)) KB)" -ForegroundColor White
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. git add $TARGET_DIR"
Write-Host "  2. git commit -m 'Add Windows Tesseract DLLs'"
Write-Host "  3. mvn clean package"
