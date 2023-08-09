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
  src = fetchurl
    {
      url = "https://github.com/vial-kb/vial-gui/releases/download/v${version}/Vial-v${version}.dmg";
      sha256 = "sha256-eIOv9TQBEzdfPHoeC+O/MrXmm7jkvMiS9u0awzZXuUA=";
    };

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
