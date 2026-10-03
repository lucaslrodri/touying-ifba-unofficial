// Body of the `elements/emphasis` test: included by test.typ (Tytanic) and by /tests.typ (the catalogue).
#import "../../common.typ": *

== Inline emphasis
#[
#set text(size: .75em)
#table(columns: (auto, auto, 1fr), [Syntax], [Color], [Result],
  [`*bold*` / `#strong[..]`], [neutral-darkest], [Text with black *bold* and #strong[strong]],
  [`_italic_` / `#emph[..]`], [neutral-darkest], [Text with _italic_, #emph[emph] and *_bold italic_*],
  [`#alert[..]`, `#primary[..]` or `~~..~~`], [primary], [Text with green #alert[alert], #primary[primary] and ~~shortcut~~; #alert[with _italic_ and `raw` inside] (the shorthand only takes plain text)],
  [`#secondary[..]`], [secondary], [Text with #secondary[amber emphasis]],
  [`#tertiary[..]`], [tertiary], [#tertiary[Label:] tag at the start of the sentence, and #tertiary[red warning] in the middle],
  [`#quaternary[..]`], [quaternary], [Text with #quaternary[blue emphasis] and #quaternary[$y = 1$] with math],
  [`#underline[..]` or `~..~`], [secondary (stroke)], [Text with #underline[strong underline (pgjy)] and ~shortcut~, color unchanged; #alert[#underline[with alert]], *#underline[bold]*; Fig.~1 and Tab.~2 stay spaces],
)
]

---

=== Inside `emph-box`, `*bold*` takes the box color
#cols[#emph-box(color: colors.quaternary)[Blue box with *blue bold* and #underline[blue underline]. #alert[alert] and #tertiary[tertiary] keep their color.]][#emph-box(color: colors.tertiary)[Red box with *red bold*, _black italic_ and #underline(stroke: .14em + colors.secondary)[explicit stroke equal to the default, so still red].]]
Outside the box, bold is *black* again and the #underline[underline, amber]. `#alert` is still #alert[green].

A `;` right after `#f[..]` is swallowed by the parser (it closes the expression); use `\;`: #alert[alert]\; the text goes on.

=== Inside a pill: white *bold*, amber ~~alert~~ and #primary[primary], dark `raw`
Normal text below the pill.
