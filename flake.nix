{
  inputs = {
    nixpkgs.url     = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: with inputs; flake-utils.lib.eachDefaultSystem (system:
  let pkgs = import nixpkgs { inherit system; };
      hask = pkgs.haskell.packages.ghc98;
      watchWithGhcid = pkgs.writers.writeDashBin "watch" ''
        ${pkgs.ghcid}/bin/ghcid --command="cabal repl"
      '';
      # Wrap cabal to always run `hpack` first.
      cabalWrapped = pkgs.writers.writeDashBin "cabal" ''
        ${pkgs.hpack}/bin/hpack
        ${pkgs.cabal-install}/bin/cabal "$@"
      '';
  in rec {
    devShell = pkgs.mkShell {
      packages = with pkgs; [
        # Haskell
        cabalWrapped
        watchWithGhcid
        (hask.ghcWithPackages (ps: with ps; [
          JuicyPixels
          blaze-html
          bytestring
          http-client
          http-types
          servant
          servant-blaze
          servant-multipart
          servant-server
          shakespeare
          text
          uuid
          wai
          warp
        ]))

        # Node
        nodejs
      ];
    };
  });
}
