#import "../template.typ": *
#show: chapter

= Colors and logo <colors>

The palette starts from the brand of the Institutos Federais. Its two colors, green and red, are the classic
complementary pair of the painter's color wheel; the theme adds the other one, amber and blue, which sit almost
opposite to each other and fill the gaps the brand colors leave. The four bases are thus spread around the wheel, and
each has a role: green carries the identity, amber marks and highlights, red is for exercises and blue for examples.

#let bases = ("primary", "secondary", "tertiary", "quaternary")
#let hue(c) = color.hsl(c).components().first()
#let wheel(size: 11em) = {
  let r = size / 2
  let (r-out, r-in) = (r * .8, r * .56)
  let pt(a, rad) = (r + rad * calc.cos(a), r - rad * calc.sin(a))
  // `body` anchored at the point: centered, or growing away from the wheel (`outward`, for the labels)
  let at(a, rad, body, outward: false) = {
    let (x, y) = pt(a, rad)
    let side = if not outward or calc.abs(calc.cos(a)) < .3 { center } else if calc.cos(a) > 0 { left } else { right }
    place(dx: x, dy: y, box(width: 0pt, height: 0pt, place(side + horizon, body)))
  }
  let n = 120
  pad(left: 3.6em, right: 2.6em, box(width: size, height: size, {
    for i in range(n) {
      let (a, b) = (i * 360deg / n, (i + 1) * 360deg / n + .5deg)
      place(polygon(fill: color.hsl(a, 80%, 52%), pt(a, r-out), pt(b, r-out), pt(b, r-in), pt(a, r-in)))
    }
    // the two pairs: the brand colors and the ones that complete the wheel
    for (a, b) in (("primary", "tertiary"), ("secondary", "quaternary")) {
      place(line(start: pt(hue(colors.at(a)), r-in), end: pt(hue(colors.at(b)), r-in), stroke: (paint: luma(120), thickness: .6pt, dash: "dashed")))
    }
    for f in bases {
      let c = colors.at(f)
      at(hue(c), (r-out + r-in) / 2, circle(radius: .62em, fill: c, stroke: 1.5pt + white))
      at(hue(c), r-out + .5em, outward: true, text(size: .85em, fill: colors.at(f + "-dark"), weight: "bold", hyphenate: false, f))
    }
  }))
}

#grid(
  columns: (auto, 1fr), column-gutter: 2em, align: horizon,
  wheel(),
  table(
    columns: (auto, auto, auto, 1fr),
    table.header([Family], [Base], [Hue], [Origin]),
    ..bases.zip((
      [IF green (Pantone 362 C)], [complement of the blue], [IF red (Pantone 187 C)], [complement of the amber],
    )).map(((f, origin)) => (raw(f), raw(upper(colors.at(f).to-hex())), [#calc.round(hue(colors.at(f)).deg())°], origin)).flatten(),
  ),
)

The green and the red are the HEX values printed in the brand manual of the Institutos Federais (2015).

Five families of seven tones, the four above and a neutral gray. The light tones serve as fills of highlights and
boxes, the dark ones as text on white: IF green is a mid-tone, so small green text reads better in `primary-dark`.

#let families = ("primary", "secondary", "tertiary", "quaternary", "neutral")
#let tones = ("darkest", "darker", "dark", "", "light", "lighter", "lightest")
#let key(family, tone) = if tone == "" { family } else { family + "-" + tone }
#let swatch(c) = {
  let ink = if c.luma().components().first() > 60% { black } else { white }
  block(width: 100%, height: 2.4em, fill: c, radius: .25em, stroke: .5pt + luma(210),
    align(center + horizon, text(size: .7em, fill: ink, upper(c.to-hex()))))
}

#grid(
  columns: (auto,) + (1fr,) * 7, gutter: .35em, align: center + horizon,
  [], ..tones.map(t => text(size: .8em, if t == "" { [base] } else { raw("-" + t) })),
  ..families.map(f => (align(left, raw(f)), ..tones.map(t => swatch(colors.at(key(f, t)))))).flatten(),
)

The tones are derived from the base in RGB: `darken(75%)`, `darken(55%)`, `darken(30%)`, the base, `lighten(30%)`,
`lighten(60%)` and `lighten(85%)`. The neutral family follows Touying's default instead, from black to white.

```example
#highlight(fill: colors.tertiary-lighter)[red fill]
and #text(fill: colors.primary-dark)[dark green text].
```

== The logo

The brand belongs to the Instituto Federal da Bahia and is not covered by the license of the package. The files in
`assets/` are the official vector artwork, with the colors of the brand manual: `ifba-logo` is the complete horizontal
version, the one the IFBA asks for outside the institution, and `ifba-logo-short` the short one. The theme itself
draws the lettering in IF green (`logo-green`), in the footer and on the cover, where it sits better next to the green
texts; that is a choice of this unofficial theme, not a version of the brand. On a dark background, use the white
negative version (`logo-white`). In either case keep the proportions, leave one module (a square of the symbol) of
clear space around the logo and do not use parts of the symbol on their own.

#reference("constants", "colors", "ifba-logo", "ifba-logo-short", "logo-green", "logo-white")
