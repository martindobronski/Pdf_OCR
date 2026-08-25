# download-tesseract-windows.ps1
# Downloads Tesseract OCR Windows binaries for bundling
# Run this script on Windows to populate src\main\resources\native\windows-x64\

$ErrorActionPreference = "Stop"

$TESSERACT_VERSION = "5.4.0.20240606"
$DOWNLOAD_URL = "https://github.com/UB-Mannheim/tesseract/releases/download/v$TESSERACT_VERSION/tesseract-ocr-w64-setup-$TESSERACT_VERSION.exe"
$EXTRACT_DIR = "$env:TEMP\tesseract_ocr"
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
$installerPath = "$env:TEMP\tesseract_ocr_setup.exe"
try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $installerPath -UseBasicParsing
    Write-Host "Download complete: $installerPath" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Download failed." -ForegroundColor Red
    Write-Host "Please download manually from:"
    Write-Host "  $DOWNLOAD_URL"
    Write-Host ""
    Write-Host "After downloading, place the installer at: $installerPath"
    Write-Host "Then run this script again."
    exit 1
}

# Clean extraction directory
if (Test-Path $EXTRACT_DIR) {
    Remove-Item -Path $EXTRACT_DIR -Recurse -Force
}

Write-Host ""
Write-Host "Installing Tesseract (silent) to $EXTRACT_DIR ..." -ForegroundColor Yellow

# NSIS silent install - /S must be uppercase, /D=path must be last, no quotes around path
$nsisArgs = "/S /D=$EXTRACT_DIR"
$process = Start-Process -FilePath $installerPath -ArgumentList $nsisArgs -Wait -NoNewWindow -PassThru

if ($process.ExitCode -ne 0) {
    Write-Host "WARNING: Installer exited with code $($process.ExitCode)" -ForegroundColor DarkYellow
}

# Wait a moment for files to settle
Start-Sleep -Seconds 2

# Debug: show what was installed
Write-Host ""
Write-Host "Checking installation directory..." -ForegroundColor Yellow
if (Test-Path $EXTRACT_DIR) {
    Write-Host "Contents of $EXTRACT_DIR :" -ForegroundColor Cyan
    Get-ChildItem -Path $EXTRACT_DIR -Filter "*.dll" -Recurse | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "Extraction directory does not exist!" -ForegroundColor Red
}

# Also check default install path
$defaultInstall = "C:\Program Files\Tesseract-OCR"
if (Test-Path $defaultInstall) {
    Write-Host ""
    Write-Host "Found default installation at: $defaultInstall" -ForegroundColor Cyan
    Write-Host "Contents:" -ForegroundColor Cyan
    Get-ChildItem -Path $defaultInstall -Filter "*.dll" | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor DarkGray
    }
}

# Search for DLLs in both locations
$searchPaths = @($EXTRACT_DIR, $defaultInstall)

# List of DLLs to find and copy
$dlls = @(
    "tesseract.dll",
    "leptonica-1.82.0.dll",
    "leptonica-1.81.0.dll",
    "leptonica-1.80.0.dll",
    "libarchive-13.dll",
    "libarchive.dll",
    "libpng16-16.dll",
    "libpng16.dll",
    "libjpeg-8.dll",
    "libjpeg.dll",
    "libtiff-6.dll",
    "libtiff.dll",
    "libwebp-7.dll",
    "libwebp.dll",
    "libwebpmux-3.dll",
    "libwebpmux.dll",
    "libsharpyuv-0.dll",
    "libsharpyuv.dll",
    "libopenjp2-7.dll",
    "libopenjp2.dll",
    "libzstd.dll",
    "liblzma-5.dll",
    "liblzma.dll",
    "liblz4.dll",
    "liblz4-1.dll",
    "libzlib.dll",
    "zlib1.dll",
    "gcc_s_seh-1.dll",
    "libwinpthread-1.dll",
    "libstdc++-6.dll"
)

Write-Host ""
Write-Host "Copying DLLs to $TARGET_DIR..." -ForegroundColor Yellow

$copiedCount = 0
foreach ($dll in $dlls) {
    $found = $false
    foreach ($searchPath in $searchPaths) {
        # Search in root and subdirectories
        $sourcePath = Join-Path $searchPath $dll
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $TARGET_DIR -Force
            Write-Host "  Copied: $dll (from $searchPath)" -ForegroundColor Green
            $copiedCount++
            $found = $true
            break
        }
        # Also check 'lib' subdirectory
        $sourcePathLib = Join-Path $searchPath "lib\$dll"
        if (Test-Path $sourcePathLib) {
            Copy-Item -Path $sourcePathLib -Destination $TARGET_DIR -Force
            Write-Host "  Copied: $dll (from $searchPath\lib)" -ForegroundColor Green
            $copiedCount++
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Host "  Not found: $dll" -ForegroundColor DarkYellow
    }
}

# Also try to find any unknown DLLs that might be needed
Write-Host ""
Write-Host "Scanning for additional DLLs in installation..." -ForegroundColor Yellow
foreach ($searchPath in $searchPaths) {
    if (Test-Path $searchPath) {
        Get-ChildItem -Path $searchPath -Filter "*.dll" -ErrorAction SilentlyContinue | ForEach-Object {
            $target = Join-Path $TARGET_DIR $_.Name
            if (-not (Test-Path $target)) {
                Copy-Item -Path $_.FullName -Destination $TARGET_DIR -Force
                Write-Host "  Additional: $($_.Name)" -ForegroundColor DarkGreen
                $copiedCount++
            }
        }
    }
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
Write-Host "Files in target directory:" -ForegroundColor Cyan
Get-ChildItem -Path $TARGET_DIR -Filter "*.dll" | ForEach-Object {
    Write-Host "  $($_.Name) ($([math]::Round($_.Length/1KB)) KB)" -ForegroundColor White
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review the DLLs in $TARGET_DIR"
Write-Host "  2. Commit them to the repository"
Write-Host "  3. Build with: mvn clean package"
