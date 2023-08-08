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
      url = "https://download.zotero.org/client/release/${version}/Zotero-${version}.dmg";
      sha256 = "sha256-5D5a2665aWF/78LgZxLY7M5g8JhqXvnMWqSResvBo2A=";
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
