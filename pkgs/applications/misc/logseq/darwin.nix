{ lib
, stdenv
, fetchurl
, undmg
, pname
, version
, meta
}:


stdenv.mkDerivation {
  inherit pname version meta;
  src =
    if stdenv.isAarch64 then
      (fetchurl
        {
          url = "https://github.com/logseq/logseq/releases/download/${version}/Logseq-darwin-arm64-${version}.dmg";
          hash = "sha256-qsWBoiFSpPeP3hB5mZs16KHkapo5G+u5+gAnO5uAbW8=";
        })
    else
      (
        fetchurl
          {
            url = "https://github.com/logseq/logseq/releases/download/${version}/Logseq-darwin-x64-${version}.dmg";
            sha256 = "sha256-ENmoDy1fj9FV+SHwNxiB16FlE+yQVxFP5KhAP8ZqM4k=";
          });

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    cp -r *.app $out/Applications
  '';
}
