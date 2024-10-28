{
  lib,
  stdenv,
  fetchFromGitHub,
  bzip2,
  cmake,
  yaml-cpp,
  nlohmann_json,
  zstd,
  reproc,
  spdlog,
  tl-expected,
  libmamba,
}: let
yaml-cpp' = yaml-cpp.override {static = true;};
  libmamba' = libmamba.overrideAttrs (oldAttrs: {
    cmakeFlags = [
      (lib.cmakeBool "BUILD_LIBMAMBA" true)
      (lib.cmakeBool "BUILD_STATIC" true)
    ];
  });

in
  stdenv.mkDerivation rec {
    pname = "micromamba";
    version = "2.0.2";

    src = fetchFromGitHub {
      owner = "mamba-org";
      repo = "mamba";
      rev = "micromamba-" + version;
      hash = "sha256-sxZDlMFoMLq2EAzwBVO++xvU1C30JoIoZXEX/sqkXS0=";
    };

    nativeBuildInputs = [cmake];

    buildInputs = [
      reproc
      spdlog
      nlohmann_json
      tl-expected
      zstd
      bzip2
      yaml-cpp'
      libmamba'
    ];

    cmakeFlags = [
      (lib.cmakeBool "BUILD_MICROMAMBA" true)
      (lib.cmakeBool "BUILD_STATIC" true)
    ];

    meta = with lib; {
      description = "Reimplementation of the conda package manager";
      homepage = "https://github.com/mamba-org/mamba";
      license = licenses.bsd3;
      platforms = platforms.all;
      maintainers = with maintainers; [mausch];
      mainProgram = "micromamba";
    };
  }
