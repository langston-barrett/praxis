{ pkgs ? import <nixpkgs> { }
}:

pkgs.mkShell {
  buildInputs = [
    # TypeScript
    pkgs.deno
    pkgs.nodePackages.eslint
  ];
}
