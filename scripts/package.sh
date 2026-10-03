#!/bin/sh
# Assembles the files of the package into <target>/preview/<name>/<version>/ (default target: dist/), the layout of
# `packages/` in https://github.com/typst/packages, so <target> also works as a package path:
# `typst init --package-path dist @preview/touying-ifba-unofficial:<version> deck`.
#
# Only the list below is the package: it is what scripts/install.sh and scripts/install.ps1 copy into the `local`
# namespace (keep the three lists in step) and what would go to Typst Universe. The rest of the repository (tests,
# manual, scripts, CI) stays out.
set -eu
cd "$(dirname "$0")/.."

files="typst.toml LICENSE LICENSE-MIT-0 README.md thumbnail.png src assets template"

name=$(sed -n 's/^name *= *"\(.*\)"/\1/p' typst.toml | head -n 1)
version=$(sed -n 's/^version *= *"\(.*\)"/\1/p' typst.toml | head -n 1)
target=${1:-dist}
out="$target/preview/$name/$version"

fail() {
  echo "error: $*" >&2
  exit 1
}

# A release tag (`v<version>`), when given by the CI, must match the manifest.
if [ -n "${RELEASE_TAG:-}" ] && [ "$RELEASE_TAG" != "v$version" ]; then
  fail "tag $RELEASE_TAG does not match the version of typst.toml ($version)"
fi

rm -rf "$out"
mkdir -p "$out"
for f in $files; do
  [ -e "$f" ] || fail "$f is missing"
  mkdir -p "$out/$(dirname "$f")"
  cp -R "$f" "$out/$f"
done
find "$out" -name .DS_Store -delete

# Every import of the package itself must use this version, and the sources the name `@preview/...`, which the
# installers rewrite to `@local/...`: a deck created from the template has to compile untouched. The README is what
# people copy from, and it shows `@local/...`, the namespace the package is installed into.
if grep -rn "@local/" "$out" --include='*.typ' >&2; then
  fail "the files above import from @local; the sources must use @preview/$name:$version"
fi
stale=$(grep -rnoE "@(preview|local)/$name:[0-9]+\.[0-9]+\.[0-9]+" "$out" --include='*.typ' --include='*.md' \
  | grep -vE ":@(preview|local)/$name:$version\$" || true)
if [ -n "$stale" ]; then
  echo "$stale" >&2
  fail "the references above do not point to version $version"
fi

# The README reaches the manual, the example deck and its pictures by relative paths, which work on GitHub: they would
# have to become URLs at the tag of the version before a publication on Typst Universe, where docs/ and example/ do
# not exist.

echo "$out"
