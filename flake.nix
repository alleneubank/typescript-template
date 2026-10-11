{
  description = "TypeScript project template";

  inputs = {
    # Track the latest stable release channel: recent tool versions AND fully
    # Hydra-built/cached for darwin. nixpkgs-unstable lags on darwin for some
    # packages, which forces slow source builds; stable avoids that trap.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";

    # Uncomment for overlays that require unfree packages (e.g., atlas-overlay)
    # nixpkgs-unfree.url = "github:numtide/nixpkgs-unfree/nixos-26.05";
    # nixpkgs-unfree.inputs.nixpkgs.follows = "nixpkgs";
    tilt-overlay = {
      url = "github:alleneubank/tilt-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    tilt-overlay,
    ...
  } @ inputs: let
    # Official-binary overlays shadow nixpkgs packages for tools where upstream
    # release artifacts are the source of truth.
    overlays = [
      tilt-overlay.overlays.default
    ];

    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    # Bun 1.4.3 official release zips. Hashes are SHASUMS256.txt digests
    # re-encoded as SRI for fetchurl. nixpkgs on this channel predates 1.4.3.
    bunVersion = "1.4.3";
    bunSources = {
      x86_64-linux = {
        archive = "bun-linux-x64.zip";
        hash = "sha256-PnMFKNiXdfA/h/BcBnh8TfQJnQo38/JS57gpyyOBbhg=";
      };
      aarch64-linux = {
        archive = "bun-linux-aarch64.zip";
        hash = "sha256-76mBPaXtckI7+Ef5FujSxHwNd2rdlyNUAmp14Q2pqiE=";
      };
      x86_64-darwin = {
        archive = "bun-darwin-x64.zip";
        hash = "sha256-YmYOZDjrhyJ4h3rMp34RUtXQMTJN82jUqBtCghFInS0=";
      };
      aarch64-darwin = {
        archive = "bun-darwin-aarch64.zip";
        hash = "sha256-gK/UwGm0am+o8+xSC+vHUKeEPkqNW5WD0prUNsAKNAM=";
      };
    };
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {
          inherit overlays system;
          config = {
            allowUnfree = true;
          };
        };
        bunSrc = bunSources.${system};
        bun = pkgs.stdenv.mkDerivation {
          pname = "bun";
          version = bunVersion;
          src = pkgs.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${bunVersion}/${bunSrc.archive}";
            hash = bunSrc.hash;
          };
          nativeBuildInputs =
            [pkgs.unzip]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.autoPatchelfHook];
          dontConfigure = true;
          dontBuild = true;
          # The upstream binary is already stripped; stripping again can break it.
          dontStrip = true;
          unpackPhase = ''
            runHook preUnpack
            unzip "$src"
            runHook postUnpack
          '';
          installPhase = ''
            runHook preInstall
            install -Dm755 bun-*/bun "$out/bin/bun"
            ln -s bun "$out/bin/bunx"
            runHook postInstall
          '';
        };
      in {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          name = "ts-dev";
          nativeBuildInputs = [
            bun
            pkgs.jq
            pkgs.ripgrep
            pkgs.coreutils
            pkgs.tilt
            pkgs.lefthook
          ];
          # Bun is pinned above to the official 1.4.3 binary. It installs
          # dependencies, runs scripts, and typechecks the project.
          shellHook =
            (pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
            '')
            + (pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
              unset SDKROOT
              unset DEVELOPER_DIR
              export PATH=/usr/bin:$PATH
            '');
        };

        devShell = self.devShells.${system}.default;
      }
    );
}
