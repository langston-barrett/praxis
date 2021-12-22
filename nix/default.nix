{ pkgs ? import <nixpkgs> { }
}:

let semgrep = pkgs.callPackage ./semgrep.nix { };
in pkgs.mkShell {
  buildInputs = [
    # semgrep
    pkgs.python3Packages.virtualenv

    # TypeScript
    pkgs.deno
    pkgs.nodePackages.eslint
  ];
}
