{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  static ? stdenv.hostPlatform.isStatic,
}:
stdenv.mkDerivation rec {
  pname = "simdjson";
  version = "3.10.1";

  src = fetchFromGitHub {
    owner = "simdjson";
    repo = "simdjson";
    rev = "v${version}";
    sha256 = "sha256-UfGt5lKmpqc21Hln4t/4KJfg+3V/hqX3UYgpCvlhkrM=";
  };

  nativeBuildInputs = [cmake];

  cmakeFlags =
    [
      (lib.cmakeBool "SIMDJSON_DEVELOPER_MODE" false)
      (lib.cmakeBool "SIMDJSON_BUILD_STATIC_LIB" static)
      (lib.cmakeBool "BUILD_SHARED_LIBS" (!static))
    ]
    ++ lib.optionals (with stdenv.hostPlatform; isPower && isBigEndian) [
      # Assume required CPU features are available, since otherwise we
      # just get a failed build.
      "-DCMAKE_CXX_FLAGS=-mpower8-vector"
    ];

  meta = with lib; {
    homepage = "https://simdjson.org/";
    description = "Parsing gigabytes of JSON per second";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [chessai];
  };
}
