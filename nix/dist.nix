{ pkgs ? import <nixpkgs> { }
}:

{
  semgrep = pkgs.callPackage ./semgrep.nix { };
}
