{
  fetchFromGitHub,
  lib,
  stdenv,
  cmake,
  fmt,
  spdlog,
  tl-expected,
  nlohmann_json,
  yaml-cpp,
  simdjson,
  reproc,
  libsolv,
  curl,
  libarchive,
  zstd,
  bzip2,
  python3Packages,
  static ? stdenv.hostPlatform.isStatic,
}:
stdenv.mkDerivation rec {
  pname = "libmamba";
  version = "2.0.2";
  src = fetchFromGitHub {
    owner = "mamba-org";
    repo = "mamba";
    rev = "libmamba-${version}";
    hash = "sha256-gAU7ORlALQly152w5URu5Ra+OYOsa3BzT1v5jBo5/Ao=";
  };
  nativeBuildInputs = [
    cmake
    python3Packages.python
  ];
  buildInputs = [
    fmt
    spdlog
    tl-expected
    nlohmann_json
    yaml-cpp
    simdjson
    reproc.override
    {static = static;}
    libsolv
    curl
    libarchive
    zstd
    bzip2
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_MAMBA" false)
    (lib.cmakeBool "BUILD_MICROMAMBA" false)
    (lib.cmakeBool "BUILD_LIBMAMBA" true)
    (lib.cmakeBool "BUILD_SHARED" (!static))
    (lib.cmakeBool "BUILD_STATIC" static)
  ];

  meta = {
    description = "Library for the fast Cross-Platform Package Manager";
    homepage = "https://github.com/mamba-org/mamba";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
    maintainers = [lib.maintainers.ericthemagician];
  };
}
