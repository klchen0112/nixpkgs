{ lib
, stdenv
, callPackage
, ...
} @args:

let
  pname = "Vial";
  version = "0.6";
  meta = with lib; {
    description = "An Open-source QMK GUI fork for configuring your keyboard in real time";
    homepage = "https://get.vial.today";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ kranzes ];
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };
  extraArgs = removeAttrs args [ "callPackage" ];
in
if stdenv.isDarwin then callPackage ./darwin.nix (extraArgs // { inherit pname version meta; })
else callPackage ./linux.nix (extraArgs // { inherit pname version meta; })
