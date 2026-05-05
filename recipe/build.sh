#!/bin/bash
set -ex

# On macOS, $BUILD_PREFIX may transitively contain another icu (cctools ->
# tapi -> libxml2 -> icu). PyICU's setup.py probes icu-config and
# pkg-config from $PATH/$PKG_CONFIG_PATH; if it picks the build-prefix icu
# instead of the host one, _icu_.so is compiled against the wrong major
# version and "import icu" fails at runtime with:
#     symbol not found in flat namespace '__ZN6icu_NN...'
#
# Hide the build-prefix icu from the toolchain (keep its .dylibs in case
# cctools/tapi dlopen them) and force PyICU to use $PREFIX explicitly.
rm -rf "$BUILD_PREFIX/include/unicode"
rm -f  "$BUILD_PREFIX/lib/pkgconfig"/icu-*.pc
rm -f  "$BUILD_PREFIX/bin/icu-config"

# PyICU's setup.py splits these env vars on `:` (os.pathsep), not spaces.
# Use `:` or everything collapses into one mangled arg.
export PYICU_INCLUDES="$PREFIX/include"
export PYICU_CFLAGS="-I$PREFIX/include:-std=c++17"
export PYICU_LFLAGS="-L$PREFIX/lib:-Wl,-rpath,$PREFIX/lib"
export PYICU_LIBRARIES="icui18n:icuuc:icudata"

# Used by setup.py only for a legacy `< '58'` check.
export ICU_VERSION="$(pkg-config --modversion icu-i18n)"

$PYTHON -m pip install . --no-deps --no-build-isolation -vv
