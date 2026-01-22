#!/bin/bash

# Script to copy dSYM files from Swift Package Manager dependencies
# This resolves the "Upload Symbols Failed" warnings for Firebase frameworks

# Exit on error
set -e

echo "🔍 Searching for SPM dSYM files..."

# Find all dSYM files in the build directory
DSYM_DIR="${BUILD_DIR}/${CONFIGURATION}"
DERIVED_DATA="${BUILD_DIR}/../../.."

# Search for dSYMs in DerivedData
find "${DERIVED_DATA}" -name "*.dSYM" -type d | while read -r dsym; do
    DSYM_NAME=$(basename "$dsym")
    
    # Check if this is a Firebase framework or Google framework
    if [[ "$DSYM_NAME" == *"Firebase"* ]] || [[ "$DSYM_NAME" == *"Google"* ]]; then
        echo "📦 Found: $DSYM_NAME"
        
        # Copy to the built products directory if not already there
        DEST="${BUILT_PRODUCTS_DIR}/${DSYM_NAME}"
        if [ ! -d "$DEST" ]; then
            echo "   ↳ Copying to ${BUILT_PRODUCTS_DIR}"
            cp -R "$dsym" "${BUILT_PRODUCTS_DIR}/"
        else
            echo "   ↳ Already exists in ${BUILT_PRODUCTS_DIR}"
        fi
    fi
done

echo "✅ dSYM copy completed"
