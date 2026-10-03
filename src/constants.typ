// touying-ifba-unofficial — constants: the color palette, the IFBA logo and the code-block language table.
// Everything derived from these values (tones, `config-colors`, the footer logo) lives in the other modules.

/// Seven-tone ramp of a base color, derived in RGB: `darkest`/`darker`/`dark` by `darken(75% / 55% / 30%)` and
/// `light`/`lighter`/`lightest` by `lighten(30% / 60% / 85%)`. The base tone itself is inserted by the caller.
///
/// #test(
///   `_ramp(red).keys() == ("darkest", "darker", "dark", "light", "lighter", "lightest")`,
///   `_ramp(red).dark == red.darken(30%)`,
///   `_ramp(red).lightest == red.lighten(85%)`,
/// )
/// -> dictionary
#let _ramp(
  /// Base color of the family. -> color
  c,
) = (
  darkest: c.darken(75%), darker: c.darken(55%), dark: c.darken(30%),
  light: c.lighten(30%), lighter: c.lighten(60%), lightest: c.lighten(85%),
)

/// Ramp of the neutral family, following Touying's default: `#808080` ± thirds, ending in pure black and white.
///
/// #test(
///   `_neutral-ramp(gray).darkest == rgb("#000000")`,
///   `_neutral-ramp(gray).lightest == rgb("#ffffff")`,
/// )
/// -> dictionary
#let _neutral-ramp(
  /// Base gray. -> color
  c,
) = (
  darkest: rgb("#000000"), darker: c.darken(66.667%), dark: c.darken(33.333%),
  light: c.lighten(33.333%), lighter: c.lighten(66.667%), lightest: rgb("#ffffff"),
)

/// The theme palette: the two colors of the Institutos Federais brand (green and red, as printed in its 2015 brand
/// manual), the complementary pair that completes the color wheel (amber and blue) and a neutral gray. The families
/// are named after Touying's `config-colors` keys (`primary`, `secondary`, `tertiary`, `neutral`) plus `quaternary`.
/// Each family has 7 tones, `<family>-darkest`, `-darker`, `-dark`, the base, `-light`, `-lighter` and `-lightest`,
/// so `colors.primary-lighter`, `colors.quaternary-dark` etc. exist. The whole dictionary is passed to
/// `config-colors`, hence the same keys are available as `self.colors.*`.
///
/// #table(
///   columns: 3,
///   table.header([Family], [Base], [Role]),
///   [`primary`], [`#2F9E41`], [IF green: titles, `->` markers, tables, `#alert`/`#primary`, pills],
///   [`secondary`], [`#F7A800`], [amber: `-` markers, `#secondary`, quotes; `-lighter` is the highlight],
///   [`tertiary`], [`#CD191E`], [IF red: `#tertiary`, exercises],
///   [`quaternary`], [`#1C6DB8`], [blue: `#quaternary`, examples],
///   [`neutral`], [`#808080`], [`-darkest` is the bold/italic text, `-lightest` the background],
/// )
///
/// #test(
///   `colors.len() == 35`,
///   `colors.primary == rgb("#2F9E41")`,
///   `colors.secondary-lighter == colors.secondary.lighten(60%)`,
///   `colors.neutral-darkest == rgb("#000000")`,
/// )
/// -> dictionary
#let colors = {
  let base = (
    primary: rgb("#2F9E41"), secondary: rgb("#F7A800"), tertiary: rgb("#CD191E"), quaternary: rgb("#1C6DB8"),
    neutral: rgb("#808080"),
  )
  let d = base
  for (name, c) in base {
    for (tone, v) in (if name == "neutral" { _neutral-ramp(c) } else { _ramp(c) }) { d.insert(name + "-" + tone, v) }
  }
  d
}

/// Languages known to codly in code blocks. The `name` is what `#local(display-name: true)[…]` shows as a label;
/// `text` is labelled "saída" (output), in Portuguese like the other user-facing defaults of the theme.
/// -> dictionary
#let code-languages = (
  python: (name: "Python", color: rgb("#3776AB")),
  typst: (name: "Typst", color: rgb("#239DAD")),
  bash: (name: "Bash", color: rgb("#4EAA25")),
  text: (name: "saída", color: luma(120)),
)

// The logos live in their own files, assets/ifba-logo.svg and assets/ifba-logo-short.svg: the brand belongs to the
// Instituto Federal da Bahia (IFBA) and is not covered by the license of this package (see the License section of the
// README). They are the official vector artwork of the IFBA (DGCOM), with the fills set to the HEX values printed in
// the brand manual of the Institutos Federais (2015): green `#2f9e41`, red `#cd191e`, black `#000000`.
/// Official IFBA logo as an SVG string, in its complete horizontal version ("Instituto Federal de Educação, Ciência e
/// Tecnologia / Bahia"), the one the IFBA asks for outside the institution. The title slide shows it in white (see
/// @logo-white).
///
/// The brand belongs to the Instituto Federal da Bahia and is not covered by the license of the package.
///
/// ```example
/// #image(bytes(ifba-logo), height: 2em)
/// ```
/// -> str
#let ifba-logo = read("../assets/ifba-logo.svg")

/// Short horizontal version of the IFBA logo ("Instituto Federal / Bahia") as an SVG string, rendered in the footer
/// with green lettering (see @logo-green): at that size the complete version would not be readable.
///
/// ```example
/// #image(bytes(ifba-logo-short), height: 2em)
/// ```
/// -> str
#let ifba-logo-short = read("../assets/ifba-logo-short.svg")

/// A logo with its lettering in IF green instead of black, as the theme shows it in the footer: the green lettering
/// sits better next to the green rules and texts of the slide. It is a choice of this theme, not an official version
/// of the brand: @ifba-logo and @ifba-logo-short keep the official colors.
///
/// ```example
/// #image(bytes(logo-green(ifba-logo-short)), height: 2em)
/// ```
/// -> str
#let logo-green(
  /// SVG source of the logo: @ifba-logo or @ifba-logo-short. -> str
  logo,
) = logo.replace("#000000", "#2f9e41")

/// Negative version of a logo: every fill becomes white, which is the monochrome negative version of the brand
/// manual, for dark backgrounds.
///
/// ```example
/// #block(fill: colors.primary-dark, inset: .5em, image(bytes(logo-white(ifba-logo)), height: 2em))
/// ```
/// -> str
#let logo-white(
  /// SVG source of the logo: @ifba-logo or @ifba-logo-short. -> str
  logo,
) = logo.replace("#2f9e41", "#ffffff").replace("#cd191e", "#ffffff").replace("#000000", "#ffffff")
