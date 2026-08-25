# download-tesseract-windows.ps1
# Downloads Tesseract OCR Windows binaries for bundling
# Run this script on Windows to populate src/main/resources/native/windows-x64/

$ErrorActionPreference = "Stop"

$TESSERACT_VERSION = "5.5.0"
$DOWNLOAD_URL = "https://github.com/UB-Mannheim/tesseract/releases/download/v$TESSERACT_VERSION/$($TESSERACT_VERSION -replace '\.','_')-win64.exe"
$EXTRACT_DIR = "$env:TEMP\tesseract-extract"
$TARGET_DIR = "src\main\resources\native\windows-x64"

Write-Host "=== Tesseract OCR Windows Download ===" -ForegroundColor Cyan
Write-Host "Version: $TESSERACT_VERSION"
Write-Host ""

# Create target directory
if (-not (Test-Path $TARGET_DIR)) {
    New-Item -ItemType Directory -Path $TARGET_DIR -Force | Out-Null
}

Write-Host "Downloading Tesseract $TESSERACT_VERSION..." -ForegroundColor Yellow

# Download the installer
$installerPath = "$env:TEMP\tesseract-setup.exe"
try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $installerPath -UseBasicParsing
    Write-Host "Download complete: $installerPath" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Download failed. Please download manually from:" -ForegroundColor Red
    Write-Host "  $DOWNLOAD_URL"
    Write-Host ""
    Write-Host "After downloading, place the installer at: $installerPath"
    Write-Host "Then run this script again."
    exit 1
}

Write-Host ""
Write-Host "Extracting DLLs (silent install)..." -ForegroundColor Yellow

# Silent install to temp directory
$installArgs = @(
    "/S"
    "/D=$EXTRACT_DIR"
)
Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow

# List of DLLs to copy
$dlls = @(
    "tesseract.dll",
    "leptonica-1.82.0.dll",
    "libarchive-13.dll",
    "libpng16-16.dll",
    "libjpeg-8.dll",
    "libtiff-6.dll",
    "libwebp-7.dll",
    "libwebpmux-3.dll",
    "libsharpyuv-0.dll",
    "libopenjp2-7.dll",
    "libzstd.dll",
    "liblzma-5.dll",
    "liblz4.dll",
    "libzlib.dll",
    "gcc_s_seh-1.dll",
    "libwinpthread-1.dll",
    "libstdc++-6.dll"
)

Write-Host "Copying DLLs to $TARGET_DIR..." -ForegroundColor Yellow

$copiedCount = 0
foreach ($dll in $dlls) {
    $sourcePath = Join-Path $EXTRACT_DIR $dll
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $TARGET_DIR -Force
        Write-Host "  Copied: $dll" -ForegroundColor Green
        $copiedCount++
    } else {
        Write-Host "  Not found: $dll (may not be required)" -ForegroundColor DarkYellow
    }
}

# Also copy tessdata if present
$tessdataDir = Join-Path $EXTRACT_DIR "tessdata"
if (Test-Path $tessdataDir) {
    Write-Host ""
    Write-Host "Note: Tessdata is already bundled in src/main/resources/tessdata/" -ForegroundColor Cyan
}

# Cleanup
Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $EXTRACT_DIR -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Copied $copiedCount DLLs to $TARGET_DIR"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review the DLLs in $TARGET_DIR"
Write-Host "  2. Commit them to the repository"
Write-Host "  3. Build with: mvn clean package"
