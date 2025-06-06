{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  sqlite,
  xcbuildHook,
}:
let
  pname = "mps";
  version = "1.118.0";
  src = fetchFromGitHub {
    owner = "Ravenbrook";
    repo = "mps";
    tag = "release-${version}";
    hash = "sha256-3ql3jWLccgnQHKf23B1en+nJ9rxqmHcWd7aBr93YER0=";
  };

  meta = {
    description = "Flexible memory management and garbage collection library";
    homepage = "https://www.ravenbrook.com/project/mps";
    license = lib.licenses.sleepycat;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = [ lib.maintainers.thoughtpolice ];
  };
in
if stdenv.hostPlatform.isLinux then
  stdenv.mkDerivation rec {

    postPatch = ''
      # Disable -Werror to avoid biuld failure on fresh toolchains like
      # gcc-13.
      substituteInPlace code/gc.gmk --replace-fail '-Werror ' ' '
      substituteInPlace code/gp.gmk --replace-fail '-Werror ' ' '
      substituteInPlace code/ll.gmk --replace-fail '-Werror ' ' '
    '';

    nativeBuildInputs = [ autoreconfHook ];

    buildInputs = [ sqlite ];

    inherit
      pname
      version
      src
      meta
      ;
  }
else
  stdenv.mkDerivation rec {
    sourceRoot = "${src.name}/code";

    nativeBuildInputs = [ xcbuildHook ];

    buildInputs = [ sqlite ];
    xcbuildFlags = [
      "-configuration"
      "Release"
      "-project"
      "mps.xcodeproj"
      # "-scheme"
      # "mps"
      "OTHER_CFLAGS='-Wno-error=unused-but-set-variable'"
    ];
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib
      cp "$TMPDIR/source/code/Products/Release/libmps.a" $out/lib/

      mkdir -p $out/include
      cp mps*.h $out/include/

      runHook postInstall
    '';

    inherit
      pname
      version
      src
      meta
      ;
  }
