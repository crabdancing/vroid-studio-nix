{
  description = "A Nix flake for Vroid Studio";

  inputs.erosanix.url = "github:emmanuelrosa/erosanix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.nix-gaming.url = "github:fufexan/nix-gaming";

  outputs = {
    self,
    nixpkgs,
    erosanix,
    ...
  }: {
    packages.x86_64-linux = let
      pkgs = import "${nixpkgs}" {
        system = "x86_64-linux";
      };
      # note: upstream's wine versions of mono and gecko are not available in nixpkgs's exposed package collection
      # and are handled as internal derivations, as seen here:
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/applications/emulators/wine/base.nix#L196
      # thus, we are copying them directly into our flake.
      # gecko32 = pkgs.fetchurl rec {
      #   version = "2.47.4";
      #   url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86.msi";
      #   hash = "sha256-Js7MR3BrCRkI9/gUvdsHTGG+uAYzGOnvxaf3iYV3k9Y=";
      # };
      # gecko64 = pkgs.fetchurl rec {
      #   version = "2.47.4";
      #   url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86_64.msi";
      #   hash = "sha256-5ZC32YijLWqkzx2Ko6o9M3Zv3Uz0yJwtzCCV7LKNBm8=";
      # };

      # I have tried unstable, and wine-ge can not seem to find it :(
      # sources = (import "${self.inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
      mono = pkgs.fetchurl rec {
        version = "8.1.0";
        url = "https://dl.winehq.org/wine/wine-mono/${version}/wine-mono-${version}-x86.msi";
        hash = "sha256-DtPsUzrvebLzEhVZMc97EIAAmsDFtMK8/rZ4rJSOCBA=";
      };
    in {
      default = self.packages.x86_64-linux.vroid-studio;

      vroid-studio = pkgs.callPackage ./vroid-studio.nix {
        inherit self;
        inherit (erosanix.lib.x86_64-linux) mkWindowsApp makeDesktopIcon copyDesktopIcons;

        # wine = wineWowPackages.full;
        wine = self.inputs.nix-gaming.packages.x86_64-linux.wine-ge.override {
          monos = [
            mono
          ];
          # build = "full";
        };
      };
    };

    apps.x86_64-linux.vroid-studio = {
      type = "app";
      program = "${self.packages.x86_64-linux.vroid-studio}/bin/vroid-studio";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.vroid-studio;
  };
}
