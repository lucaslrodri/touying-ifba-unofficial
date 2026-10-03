#!/bin/sh
# Installs touying-ifba-unofficial into the `local` namespace of Typst, on macOS and Linux (Windows: install.ps1), so
# that `#import "@local/touying-ifba-unofficial:<version>": *` and `typst init @local/touying-ifba-unofficial:<version>`
# work. The theme is not on Typst Universe: this is how it is installed.
#
#   sh scripts/install.sh              from a clone: installs the working copy
#   curl -fsSL https://raw.githubusercontent.com/lucaslrodri/touying-ifba-unofficial/main/scripts/install.sh | sh
#   curl -fsSL ... | sh -s -- --fonts  the same, passing options
#
# Options:
#   --fonts       also install Open Sans, the font of the theme, into the fonts folder of the user
#   --ref <ref>   branch or tag to download when not run from a clone (default: main)
#   --uninstall   remove every installed version of the package from the `local` namespace
#
# Only the files of the package are copied (the list of scripts/package.sh), into
# <data>/typst/packages/local/touying-ifba-unofficial/<version>/, where <data> is ~/Library/Application Support on
# macOS and $XDG_DATA_HOME (~/.local/share) on Linux; TYPST_PACKAGE_PATH, when set, replaces <data>/typst/packages. In
# the copy, the imports of the package itself (`@preview/...` in the repository, see scripts/link.sh) become
# `@local/...`, so a deck created from the template compiles untouched.
set -eu

# Everything runs from `main`, called on the last line: a download cut short by the network runs nothing.
main() {
  repo=lucaslrodri/touying-ifba-unofficial
  name=touying-ifba-unofficial
  files="typst.toml LICENSE LICENSE-MIT-0 README.md thumbnail.png src assets template"   # as in scripts/package.sh
  # the static cuts of Open Sans, at the commit scripts/fonts.sh uses
  opensans=https://raw.githubusercontent.com/googlefonts/opensans/bd7e37632246368c60fdcbd374dbf9bad11969b6/fonts/ttf
  opensans_cuts="Regular Italic SemiBold SemiBoldItalic Bold BoldItalic"

  ref=main
  fonts=false
  uninstall=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --fonts) fonts=true ;;
      --uninstall) uninstall=true ;;
      --ref) [ $# -ge 2 ] || fail "--ref needs a branch or a tag"; ref=$2; shift ;;
      -h | --help) sed -n '2,19p' "$0" 2> /dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) fail "unknown option: $1 (see --help)" ;;
    esac
    shift
  done

  if [ -n "${TYPST_PACKAGE_PATH:-}" ]; then
    packages=$TYPST_PACKAGE_PATH
  else
    case "$(uname -s)" in
      Darwin) packages="$HOME/Library/Application Support/typst/packages" ;;
      *) packages="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages" ;;
    esac
  fi
  installed="$packages/local/$name"

  if $uninstall; then
    if [ -e "$installed" ] || [ -L "$installed" ]; then
      rm -rf "$installed"
      echo "removed $installed"
    else
      echo "nothing to remove: $installed does not exist"
    fi
    exit 0
  fi

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT

  # From a clone, the working copy is installed; otherwise (`curl ... | sh`) the repository is downloaded.
  src=""
  if [ -f "$0" ]; then
    here=$(cd "$(dirname "$0")/.." && pwd)
    if grep -q "^name *= *\"$name\"" "$here/typst.toml" 2> /dev/null; then src=$here; fi
  fi
  if [ -z "$src" ]; then
    src="$tmp/src"
    mkdir -p "$src"
    echo "downloading $repo ($ref)"
    fetch "https://github.com/$repo/archive/$ref.tar.gz" "$tmp/src.tar.gz"
    tar -xzf "$tmp/src.tar.gz" -C "$src" --strip-components 1
  fi

  version=$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$src/typst.toml" | head -n 1)
  [ -n "$version" ] || fail "no version in $src/typst.toml"
  target="$installed/$version"

  if [ -L "$target" ]; then
    fail "$target is a symbolic link (a development link?): remove it first"
  fi
  rm -rf "$target"
  mkdir -p "$target"
  for f in $files; do
    [ -e "$src/$f" ] || fail "$f is missing in $src"
    cp -R "$src/$f" "$target/$f"
  done
  find "$target" -name .DS_Store -exec rm -f {} +
  # the package imports itself as `@preview/...` in the repository: in the `local` namespace it is `@local/...`
  find "$target" -type f \( -name '*.typ' -o -name '*.md' \) -exec sh -c '
    for f; do
      sed "s|@preview/$0:|@local/$0:|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done
  ' "$name" {} +
  echo "installed $name $version in $target"

  if $fonts; then
    case "$(uname -s)" in
      Darwin) fontdir="$HOME/Library/Fonts" ;;
      *) fontdir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
    esac
    mkdir -p "$fontdir"
    for cut in $opensans_cuts; do
      fetch "$opensans/OpenSans-$cut.ttf" "$tmp/OpenSans-$cut.ttf"
      mv "$tmp/OpenSans-$cut.ttf" "$fontdir/OpenSans-$cut.ttf"
    done
    if command -v fc-cache > /dev/null 2>&1; then fc-cache -f "$fontdir" > /dev/null 2>&1 || true; fi
    echo "installed Open Sans in $fontdir"
  elif command -v typst > /dev/null 2>&1 && ! typst fonts 2> /dev/null | grep -qx "Open Sans"; then
    echo "warning: the font Open Sans is not installed: run again with --fonts, or get it from" >&2
    echo "         https://fonts.google.com/specimen/Open+Sans" >&2
  fi
  command -v typst > /dev/null 2>&1 || echo "warning: typst is not on the PATH: https://typst.app/open-source/#download" >&2

  echo
  echo "Start a deck with:"
  echo "  typst init @local/$name:$version my-deck"
  echo "or import the theme in an existing one:"
  echo "  #import \"@local/$name:$version\": *"
}

fail() {
  echo "error: $*" >&2
  exit 1
}

# Downloads <url> to <file> with curl or wget.
fetch() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL --retry 3 -o "$2" "$1" || fail "could not download $1"
  elif command -v wget > /dev/null 2>&1; then
    wget -q -O "$2" "$1" || fail "could not download $1"
  else
    fail "curl or wget is needed to download $1"
  fi
}

main "$@"
