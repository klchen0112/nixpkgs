{ lib, stdenv, fetchurl, libiconv }:

stdenv.mkDerivation rec {
  pname = "mtools";
  version = "4.0.47";

  src = fetchurl {
    url = "mirror://gnu/mtools/${pname}-${version}.tar.bz2";
    hash = "sha256-MaoGB4zD9QWRuV5xqQnFbdF52H6cvcB79DXllb18x/8=";
  };

  patches = lib.optional stdenv.hostPlatform.isDarwin ./UNUSED-darwin.patch;

  # fails to find X on darwin
  configureFlags = lib.optional stdenv.hostPlatform.isDarwin "--without-x";

  buildInputs = lib.optional stdenv.hostPlatform.isDarwin libiconv;

  doCheck = true;

  passthru = {
    updateScript = ./update.sh;
  };

  meta = with lib; {
    homepage = "https://www.gnu.org/software/mtools/";
    description = "Utilities to access MS-DOS disks";
    platforms = platforms.unix;
    license = licenses.gpl3;
  };
}
