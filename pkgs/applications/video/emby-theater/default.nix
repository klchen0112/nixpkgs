{ lib
, stdenv
, fetchurl
, unzip
}:

let
  pname = "emby-theater";
  version = "4.8.0.40";
  meta = with lib; {
    description = "A beautiful Plex music player for audiophiles, curators, and hipsters";
    homepage = "https://emby.media";
    changelog = "https://github.com/MediaBrowser/Emby.Releases/releases/tag/${version}";
    license = licenses.unfree;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-darwin" ];
  };

in
stdenv.mkDerivation {
  inherit pname version meta;
  src =
    fetchurl {
      url = "https://github.com/MediaBrowser/Emby.Releases/tree/${version}/macos/Emby.app.zip";
      sha256 = "sha256-nyRimcagef4zvTlq/9OjPQhsukKUVw0eohGZ4DrCIac=";
    };

  dontBuild = true;

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    cp -r *.app $out/Applications
  '';
}
