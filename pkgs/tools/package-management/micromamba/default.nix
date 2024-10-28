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
  yaml-cpp-static =
    yaml-cpp.override
    {
      static = true;
    };
  libmamba-static =
    libmamba.override
    {
      static = true;
      yaml-cpp = yaml-cpp-static;
    };
  reproc-static = reproc.overrideAttrs (
    oldAttrs: {
      cmakeFlags = [
        "-DCMAKE_INSTALL_LIBDIR=lib"
        "-DBUILD_SHARED_LIBS=OFF"
        "-DBUILD_STATIC_LIBS=ON"
        "-DREPROC++=ON"
        "-DREPROC_TEST=ON"
      ];
    }
  );
in
  stdenv.mkDerivation rec {
    pname = "micromamba";
    version = "2.0.2";

    src = fetchFromGitHub {
      owner = "mamba-org";
      repo = "mamba";
      rev = "micromamba-" + version;
      hash = "sha256-gAU7ORlALQly152w5URu5Ra+OYOsa3BzT1v5jBo5/Ao=";
    };

    nativeBuildInputs = [cmake];

    buildInputs = [
      reproc-static
      spdlog
      nlohmann_json
      tl-expected
      zstd
      bzip2
      yaml-cpp-static
      libmamba-static
    ];
    cmakeFlags = [
      (lib.cmakeBool "BUILD_MICROMAMBA" true)
      (lib.cmakeBool "BUILD_STATIC" true)
      (lib.cmakeBool "BUILD_LIBMAMBA" false)
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
