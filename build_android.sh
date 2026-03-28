#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Serious Python Android Build Setup..."

# 1. Prepare directory
mkdir -p build/site-packages

# 2. Package Python app (including cascades) into assets/python_lib.zip
echo "📦 Packaging Python app and dependencies for Android..."
mkdir -p assets
# Ensure the zip is recreated from scratch to avoid stale files
rm -f assets/python_lib.zip
dart run serious_python:main package python_lib --platform Android -a assets/python_lib.zip -r opencv-python -r flask -r numpy --exclude venv

# 3. Export the environment variable required by serious_python for Android build
export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/build/site-packages
echo "✅ SERIOUS_PYTHON_SITE_PACKAGES is set to: $SERIOUS_PYTHON_SITE_PACKAGES"

# 4. Run the flutter command
if [ $# -eq 0 ]; then
    echo "📱 Running 'flutter run'..."
    flutter run
else
    echo "🛠 Running '$*'..."
    $@
fi
