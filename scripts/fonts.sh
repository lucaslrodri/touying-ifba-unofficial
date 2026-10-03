#!/bin/sh
# Downloads the fonts of the theme into fonts/, which is git-ignored: Open Sans (the typeface of the brand of the
# Institutos Federais, used for the text; Typst does not bundle it) from its repository, and New Computer Modern Math
# (the equations) from CTAN. For the CI and for machines where the fonts are not installed:
# `tt run --font-path fonts` or `typst compile --font-path fonts ...`. The reference images of the test suite match
# the commit of Open Sans below and the releases 8.0.1 and 8.1.1 of New Computer Modern.
set -eu
cd "$(dirname "$0")/.."

# Static cuts of Open Sans (the Google Fonts download is a variable font), at a fixed commit of googlefonts/opensans.
opensans=https://raw.githubusercontent.com/googlefonts/opensans/bd7e37632246368c60fdcbd374dbf9bad11969b6/fonts/ttf
opensans_cuts="Regular Italic SemiBold SemiBoldItalic Bold BoldItalic"

# Typst embeds a New Computer Modern Math, not necessarily in the release of the reference images, so Math comes from
# fonts/ too.
missing=""
for cut in $opensans_cuts; do
  [ -f "fonts/OpenSans-$cut.ttf" ] || missing="$missing OpenSans-$cut.ttf"
done
[ -f fonts/NewCMMath-Regular.otf ] || missing="$missing NewCMMath-Regular.otf"
if [ -z "$missing" ]; then
  echo "fonts/ is already populated"
  exit 0
fi
echo "missing in fonts/:$missing"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p fonts
for cut in $opensans_cuts; do
  [ -f "fonts/OpenSans-$cut.ttf" ] && continue
  curl -fsSL --retry 3 -o "$tmp/OpenSans-$cut.ttf" "$opensans/OpenSans-$cut.ttf"
  mv "$tmp/OpenSans-$cut.ttf" fonts/
done
if [ ! -f fonts/NewCMMath-Regular.otf ]; then
  curl -fsSL --retry 3 -o "$tmp/newcm.zip" https://mirrors.ctan.org/fonts/newcomputermodern.zip
  unzip -q -j -o "$tmp/newcm.zip" '*NewCMMath-*.otf' -d fonts
fi
echo "fonts/: $(ls fonts | wc -l | tr -d ' ') files"
