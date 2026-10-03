<#
.SYNOPSIS
Installs touying-ifba-unofficial into the `local` namespace of Typst on Windows (macOS and Linux: install.sh; this
script also runs there under PowerShell 7).

.DESCRIPTION
After it, `#import "@local/touying-ifba-unofficial:<version>": *` and
`typst init @local/touying-ifba-unofficial:<version>` work. The theme is not on Typst Universe: this is how it is
installed.

    .\scripts\install.ps1                from a clone: installs the working copy
    irm https://raw.githubusercontent.com/lucaslrodri/touying-ifba-unofficial/main/scripts/install.ps1 | iex
    & ([scriptblock]::Create((irm <the same URL>))) -Fonts     the same, passing options

Only the files of the package are copied (the list of scripts/package.sh), into
%APPDATA%\typst\packages\local\touying-ifba-unofficial\<version>\; TYPST_PACKAGE_PATH, when set, replaces
%APPDATA%\typst\packages. In the copy, the imports of the package itself (`@preview/...` in the repository, see
scripts/link.sh) become `@local/...`, so a deck created from the template compiles untouched.

.PARAMETER Fonts
Also install Open Sans, the font of the theme, into the fonts folder of the user.

.PARAMETER Ref
Branch or tag to download when not run from a clone (default: main).

.PARAMETER Uninstall
Remove every installed version of the package from the `local` namespace.
#>
param(
  [switch]$Fonts,
  [string]$Ref = "main",
  [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # the progress bar of Windows PowerShell slows the downloads down
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$repo = "lucaslrodri/touying-ifba-unofficial"
$name = "touying-ifba-unofficial"
$files = "typst.toml", "LICENSE", "LICENSE-MIT-0", "README.md", "thumbnail.png", "src", "assets", "template"   # as in scripts/package.sh
# the static cuts of Open Sans, at the commit scripts/fonts.sh uses
$openSans = "https://raw.githubusercontent.com/googlefonts/opensans/bd7e37632246368c60fdcbd374dbf9bad11969b6/fonts/ttf"
$openSansCuts = "Regular", "Italic", "SemiBold", "SemiBoldItalic", "Bold", "BoldItalic"

# `$IsMacOS` and `$IsLinux` do not exist on Windows PowerShell 5.1, where they read as false.
$onMac = [bool](Get-Variable IsMacOS -ValueOnly -ErrorAction SilentlyContinue)
$onLinux = [bool](Get-Variable IsLinux -ValueOnly -ErrorAction SilentlyContinue)
$dataHome = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $HOME ".local/share" }

if ($env:TYPST_PACKAGE_PATH) { $packages = $env:TYPST_PACKAGE_PATH }
elseif ($onMac) { $packages = Join-Path $HOME "Library/Application Support/typst/packages" }
elseif ($onLinux) { $packages = Join-Path $dataHome "typst/packages" }
else { $packages = Join-Path $env:APPDATA "typst\packages" }
$installed = Join-Path (Join-Path $packages "local") $name

if ($Uninstall) {
  if (Test-Path -LiteralPath $installed) {
    Remove-Item -LiteralPath $installed -Recurse -Force
    Write-Host "removed $installed"
  } else {
    Write-Host "nothing to remove: $installed does not exist"
  }
  return
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("$name-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  # From a clone, the working copy is installed; otherwise (`irm ... | iex`) the repository is downloaded.
  $src = $null
  if ($PSScriptRoot) {
    $here = Split-Path -Parent $PSScriptRoot
    $manifest = Join-Path $here "typst.toml"
    if ((Test-Path -LiteralPath $manifest) -and ([IO.File]::ReadAllText($manifest) -match "(?m)^name *= *`"$name`"")) { $src = $here }
  }
  if (-not $src) {
    Write-Host "downloading $repo ($Ref)"
    $zip = Join-Path $tmp "src.zip"
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$repo/archive/$Ref.zip" -OutFile $zip
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmp "src")
    $src = (Get-ChildItem -LiteralPath (Join-Path $tmp "src") -Directory | Select-Object -First 1).FullName
  }

  if ([IO.File]::ReadAllText((Join-Path $src "typst.toml")) -notmatch '(?m)^version *= *"(.*)"') { throw "no version in $src/typst.toml" }
  $version = $Matches[1]
  $target = Join-Path $installed $version

  if (Test-Path -LiteralPath $target) {
    if ((Get-Item -LiteralPath $target -Force).LinkType) { throw "$target is a link (a development link?): remove it first" }
    Remove-Item -LiteralPath $target -Recurse -Force
  }
  New-Item -ItemType Directory -Path $target -Force | Out-Null
  foreach ($f in $files) {
    $from = Join-Path $src $f
    if (-not (Test-Path -LiteralPath $from)) { throw "$f is missing in $src" }
    Copy-Item -LiteralPath $from -Destination (Join-Path $target $f) -Recurse -Force
  }
  # the package imports itself as `@preview/...` in the repository: in the `local` namespace it is `@local/...`.
  # .NET reads and writes UTF-8 without a BOM whatever the PowerShell version (Get-Content of 5.1 would not).
  $utf8 = New-Object Text.UTF8Encoding $false
  Get-ChildItem -LiteralPath $target -Recurse -File | Where-Object { $_.Extension -in ".typ", ".md" } | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName, $utf8)
    [IO.File]::WriteAllText($_.FullName, $text.Replace("@preview/${name}:", "@local/${name}:"), $utf8)
  }
  Write-Host "installed $name $version in $target"

  $typst = Get-Command typst -ErrorAction SilentlyContinue
  if ($Fonts) {
    if ($onMac) { $fontDir = Join-Path $HOME "Library/Fonts" }
    elseif ($onLinux) { $fontDir = Join-Path $dataHome "fonts" }
    else { $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts" }
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
    foreach ($cut in $openSansCuts) {
      $file = Join-Path $fontDir "OpenSans-$cut.ttf"
      Invoke-WebRequest -UseBasicParsing -Uri "$openSans/OpenSans-$cut.ttf" -OutFile $file
      if (-not ($onMac -or $onLinux)) {
        # per-user font registration, so that the other programs see the font too (Typst reads the folder itself)
        $key = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        New-ItemProperty -Path $key -Name "Open Sans $cut (TrueType)" -Value $file -PropertyType String -Force | Out-Null
      }
    }
    Write-Host "installed Open Sans in $fontDir"
  } elseif ($typst -and -not ((& typst fonts 2>$null) -contains "Open Sans")) {
    Write-Warning "the font Open Sans is not installed: run again with -Fonts, or get it from https://fonts.google.com/specimen/Open+Sans"
  }
  if (-not $typst) { Write-Warning "typst is not on the PATH: https://typst.app/open-source/#download" }

  Write-Host ""
  Write-Host "Start a deck with:"
  Write-Host "  typst init @local/${name}:$version my-deck"
  Write-Host "or import the theme in an existing one:"
  Write-Host "  #import `"@local/${name}:$version`": *"
} finally {
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
