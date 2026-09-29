#!/usr/bin/env bash
# Build scantailor-advanced (stalib / stalib_cpp) from source on macOS.
# PyPI has no macOS wheels, so it must be compiled against Qt5 + Boost.
# Works on both Intel (x86_64) and Apple Silicon (arm64) with Homebrew.
# Usage (inside the Python env you want it installed into):
#   bash packaging/macos/build_stalib.sh
set -euo pipefail

brew install qt@5 boost pybind11

QT="$(brew --prefix qt@5)"
BOOST="$(brew --prefix boost)"
SHIM="$(pwd)/.qt-shim"
mkdir -p "$SHIM"

# setup.py links with -lQt5Core -lQt5Gui -lQt5Widgets -lQt5Xml, but Homebrew's
# Qt5 ships frameworks (QtCore.framework/...). Provide libQt5*.dylib shims.
for m in Core Gui Widgets Xml; do
  if [ ! -e "$QT/lib/libQt5$m.dylib" ]; then
    ln -sf "$QT/lib/Qt$m.framework/Versions/5/Qt$m" "$SHIM/libQt5$m.dylib"
  fi
done

INC="-I$QT/include"
for m in Core Gui Widgets Xml; do
  INC="$INC -I$QT/include/Qt$m -I$QT/lib/Qt$m.framework/Headers"
done

export QT_DIR="$QT"
export BOOST_ROOT="$BOOST"
export CFLAGS="-F$QT/lib $INC"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-F$QT/lib -L$SHIM -L$QT/lib -Wl,-rpath,$QT/lib"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-11.0}"

python -m pip install --no-cache-dir -v scantailor-advanced
python -c "import stalib, stalib_cpp; print('stalib OK:', stalib.__file__)"
