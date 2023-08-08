{ lib
, stdenvNoCC
, fetchurl
, undmg
}:

stdenvNoCC.mkDerivation rec {
  pname = "marginnote";
  version = "3.7.25";

  src = fetchurl
    {
      url = "https://marginstudy.com/mac/MarginNote3.dmg";
      hash = "sha256-RAnim2BG/HFELz8ghTddrah7PwapCJKyM0gjsNrXWtM=";
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

  meta = with lib; {
    description = "A brand new e-reader to better study and digest your books";
    homepage = "https://www.marginnote.com";
    license = licenses.unfree;
    maintainers = with maintainers; [ klchen0112 ];
    platforms = platforms.darwin;
  };
}
