{ pkgs ? import <nixpkgs> { }
}:

let semgrep = pkgs.callPackage ./semgrep.nix { };
in pkgs.mkShell {
  buildInputs = [
    # semgrep
    pkgs.python3Packages.virtualenv
    pkgs.radamsa

    # TypeScript
    pkgs.deno
    pkgs.nodePackages.eslint
  ];
}
