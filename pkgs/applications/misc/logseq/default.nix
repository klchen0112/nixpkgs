{ lib
, stdenv
, callPackage
, ...
} @args:

let
  pname = "logseq";
  version = "0.9.13";
  extraArgs = removeAttrs args [ "callPackage" ];
  meta = with lib; {
    description = "A local-first, non-linear, outliner notebook for organizing and sharing your personal knowledge base";
    homepage = "https://github.com/logseq/logseq";
    changelog = "https://github.com/logseq/logseq/releases/tag/${version}";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ klchen0112 ];
    platforms = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
  };
in
if stdenv.isDarwin then callPackage ./darwin.nix (extraArgs // { inherit pname version meta; })
else callPackage ./linux.nix (extraArgs // { inherit pname version meta; })
