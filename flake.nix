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
    # nub-overlay supplies nub from the official prebuilt release tarballs. It
    # preserves nub's bin/ + runtime/ sibling layout, so TypeScript execution
    # works the same way inside and outside Nix.
    nub-overlay = {
      url = "github:alleneubank/nub-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
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
    nub-overlay,
    tilt-overlay,
    ...
  } @ inputs: let
    # Official-binary overlays shadow nixpkgs packages for tools where upstream
    # release artifacts are the source of truth.
    overlays = [
      nub-overlay.overlays.default
      tilt-overlay.overlays.default
    ];

    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {
          inherit overlays system;
          config = {
            allowUnfree = true;
          };
        };
      in {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          name = "ts-dev";
          nativeBuildInputs = [
            pkgs.nub
            pkgs.jq
            pkgs.ripgrep
            pkgs.coreutils
            pkgs.tilt
            pkgs.lefthook
          ];
          # nub auto-provisions Node from .node-version on first run, so there is
          # no version-manager shell hook (fnm/corepack are gone).
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
