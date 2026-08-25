#!/bin/bash
# fix-rpaths.sh - Fix Rpaths and prepare macOS dylibs for bundling
# Run this after copying dylibs to src/main/resources/native/macos-aarch64/

set -e

NATIVE_DIR="src/main/resources/native/macos-aarch64"

if [ ! -d "$NATIVE_DIR" ]; then
    echo "ERROR: Directory $NATIVE_DIR not found"
    exit 1
fi

echo "Fixing rpaths for macOS dylibs in $NATIVE_DIR..."

BREW_LIBS=(
    "libtesseract.5.dylib"
    "libleptonica.6.dylib"
    "libarchive.13.dylib"
    "libtiff.6.dylib"
    "libjpeg.8.dylib"
    "libwebp.7.dylib"
    "libopenjp2.7.dylib"
    "libpng16.16.dylib"
    "libzstd.1.dylib"
    "liblzma.5.dylib"
    "liblz4.1.dylib"
    "libb2.1.dylib"
    "libgif.dylib"
    "libwebpmux.3.dylib"
    "libsharpyuv.0.dylib"
)

echo "Step 1: Fixing dylib identities..."
for lib in "${BREW_LIBS[@]}"; do
    LIB_PATH="$NATIVE_DIR/$lib"
    if [ -f "$LIB_PATH" ]; then
        install_name_tool -id "@loader_path/$lib" "$LIB_PATH"
        echo "  Fixed ID: $lib"
    fi
done

echo "Step 2: Fixing dylib dependencies..."
for lib in "${BREW_LIBS[@]}"; do
    LIB_PATH="$NATIVE_DIR/$lib"
    if [ -f "$LIB_PATH" ]; then
        DEPS=$(otool -L "$LIB_PATH" | grep -o '/opt/homebrew[^ ]*' || true)
        for dep in $DEPS; do
            dep_name=$(basename "$dep")
            if [[ " ${BREW_LIBS[@]} " =~ " ${dep_name} " ]]; then
                install_name_tool -change "$dep" "@loader_path/$dep_name" "$LIB_PATH"
                echo "  Fixed dep in $lib: $dep_name"
            fi
        done
    fi
done

echo "Step 3: Fixing @rpath references..."
for lib in "${BREW_LIBS[@]}"; do
    LIB_PATH="$NATIVE_DIR/$lib"
    if [ -f "$LIB_PATH" ]; then
        RPATH_DEPS=$(otool -L "$LIB_PATH" | grep -o '@rpath/[^ ]*' || true)
        for dep in $RPATH_DEPS; do
            dep_name=$(basename "$dep")
            install_name_tool -change "$dep" "@loader_path/$dep_name" "$LIB_PATH"
            echo "  Fixed @rpath in $lib: $dep_name"
        done
    fi
done

echo "Step 4: Creating unversioned copies..."
for lib in "${BREW_LIBS[@]}"; do
    LIB_PATH="$NATIVE_DIR/$lib"
    if [ -f "$LIB_PATH" ]; then
        unversioned_name=$(echo "$lib" | sed 's/\.[0-9]*\.dylib/.dylib/')
        if [ "$lib" != "$unversioned_name" ]; then
            cp "$LIB_PATH" "$NATIVE_DIR/$unversioned_name"
            echo "  Created: $unversioned_name"
        fi
    fi
done

echo "Step 5: Ad-hoc codesigning..."
for f in "$NATIVE_DIR"/*.dylib; do
    codesign --force --sign - "$f" 2>/dev/null
done
echo "  All dylibs signed"

echo ""
echo "Step 6: Verifying rpaths..."
for lib in "${BREW_LIBS[@]}"; do
    LIB_PATH="$NATIVE_DIR/$lib"
    if [ -f "$LIB_PATH" ]; then
        echo "=== $lib ==="
        otool -L "$LIB_PATH" | head -5
        echo ""
    fi
done

echo "Done! All rpaths fixed, copies created, and dylibs signed."
