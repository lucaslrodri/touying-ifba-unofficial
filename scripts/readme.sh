#!/bin/sh
# Keeps README.md and thumbnail.png in step with the two decks. For template/main.typ and example/main.typ it renders
# the pages, joins them into one picture (docs/readme/sheet.typ -> docs/readme/<deck>.png) and rewrites what README.md
# has between `<!-- <deck>:begin ... -->` and `<!-- <deck>:end -->`: the source of the deck, then the picture.
# thumbnail.png is the cover of the template, which Typst Universe wants as the template is initialized.
#
# The package is installed from the repository into the `local` namespace (scripts/install.sh), not from Typst
# Universe, so the README is the one of the repository: the decks are shown with the import a user writes
# (`@local/...`; the sources import `@preview/...`, see scripts/link.sh) and the pictures are referenced by a relative
# path. Publishing on Typst Universe would take the `@preview` import and the raw.githubusercontent.com URL of the
# tag `v<version>` here, since docs/ is not published there.
#
# `sh scripts/readme.sh --check` writes nothing: it fails when README.md is out of date and only warns when a picture
# is, since the pixels depend on the release of the installed fonts. scripts/local.sh runs it before every commit.
set -eu
cd "$(dirname "$0")/.."

decks="template example"
out=docs/readme
tmp=$out/.tmp   # inside the project, where sheet.typ can read the pages
ppi=72          # two slides of 842pt side by side: 1768 px
thumbnail_ppi=144   # 1684 px: Typst Universe asks for 1080 px or more on the longer edge

fail() {
  echo "error: $*" >&2
  exit 1
}

check=false
[ "${1:-}" = "--check" ] && check=true

name=$(sed -n 's/^name *= *"\(.*\)"/\1/p' typst.toml | head -n 1)
url=$out

fonts=""
[ -d fonts ] && fonts="--font-path fonts"

rm -rf "$tmp"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT
cp README.md "$tmp/README.md"

for deck in $decks; do
  typst compile $fonts "$deck/main.typ" "$tmp/$deck-{p}.svg"
  pages=$(ls "$tmp/$deck"-*.svg | wc -l | tr -d ' ')
  typst compile --root . $fonts --ppi "$ppi" --input deck="$deck" --input pages="$pages" --input dir=.tmp \
    "$out/sheet.typ" "$tmp/$deck.png"

  {
    echo '```typst'
    sed "s|@preview/$name:|@local/$name:|" "$deck/main.typ" | awk 1
    echo '```'
    echo
    echo "![The $pages pages of $deck/main.typ]($url/$deck.png)"
  } > "$tmp/$deck.md"

  for marker in "^<!-- $deck:begin" "^<!-- $deck:end -->\$"; do
    [ "$(grep -c -- "$marker" README.md)" = 1 ] || fail "README.md must have exactly one line matching '$marker'"
  done
  awk -v deck="$deck" -v block="$tmp/$deck.md" '
    index($0, "<!-- " deck ":begin") == 1 { print; while ((getline line < block) > 0) print line; skip = 1; next }
    $0 == "<!-- " deck ":end -->" { skip = 0 }
    !skip { print }
  ' "$tmp/README.md" > "$tmp/README.new"
  mv "$tmp/README.new" "$tmp/README.md"
done

typst compile $fonts -f png --pages 1 --ppi "$thumbnail_ppi" template/main.typ "$tmp/thumbnail.png"

if $check; then
  for deck in $decks; do
    cmp -s "$tmp/$deck.png" "$out/$deck.png" || echo "warning: $out/$deck.png is out of date" >&2
  done
  cmp -s "$tmp/thumbnail.png" thumbnail.png || echo "warning: thumbnail.png is out of date" >&2
  cmp -s "$tmp/README.md" README.md || fail "README.md is out of date with the decks: run \`sh scripts/readme.sh\`"
  exit 0
fi

# only what changed is written, so an up-to-date README keeps its timestamp
for deck in $decks; do
  cmp -s "$tmp/$deck.png" "$out/$deck.png" || { mv -f "$tmp/$deck.png" "$out/$deck.png" && echo "$out/$deck.png"; }
done
cmp -s "$tmp/thumbnail.png" thumbnail.png || { mv -f "$tmp/thumbnail.png" thumbnail.png && echo "thumbnail.png"; }
cmp -s "$tmp/README.md" README.md || { cp "$tmp/README.md" README.md && echo "README.md"; }
