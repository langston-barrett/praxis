# https://github.com/NixOS/nixpkgs/pull/141763
{ lib, fetchzip, stdenvNoCC }:

stdenvNoCC.mkDerivation rec {
  pname = "semgrep";
  version = "0.77.0";

  src = fetchzip {
    url = "https://github.com/returntocorp/semgrep/releases/download/v${version}/semgrep-v${version}-ubuntu-16.04.tgz";
    sha256 = "0jix7b6nwac28hflqgrzz8ps2vnfrqq1waf87jba4n3hr29c9fxc";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp * $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "Lightweight static analysis for many languages";
    homepage = "https://semgrep.dev";
    license = licenses.lgpl21Only;
    mainProgram = "semgrep-core";
    platforms = [ "x86_64-linux" ];
  };
}
