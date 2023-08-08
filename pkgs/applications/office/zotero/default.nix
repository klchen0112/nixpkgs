{ lib
, stdenv
, callPackage
, ...
} @args:

let
  pname = "zotero";
  version = "6.0.26";
  meta = with lib; {
    homepage = "https://www.zotero.org";
    description = "Collect, organize, cite, and share your research sources";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.agpl3Only;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ i077 ];
  };
  extraArgs = removeAttrs args [ "callPackage" ];

in
if stdenv.isDarwin then callPackage ./darwin.nix (extraArgs // { inherit pname version meta; })
else callPackage ./linux.nix (extraArgs // { inherit pname version meta; })
