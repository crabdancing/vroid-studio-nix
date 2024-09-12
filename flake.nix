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
      # approach is based on what upstream (nix-gaming) is doing:
      # https://github.com/fufexan/nix-gaming/blob/master/pkgs/wine/default.nix
      # NOTE: the wine-mono version is pinned to our nixpkgs's wine/sources.nix version of wine-mono.
      # As such, this MAY break if you bump nixpkgs depending on the circumstances.
      # This may offer a hint if you are currently troubleshooting something.
      sources = (import "${self.inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
    in {
      default = self.packages.x86_64-linux.vroid-studio;

      vroid-studio = pkgs.callPackage ./vroid-studio.nix {
        inherit self;
        inherit (erosanix.lib.x86_64-linux) mkWindowsApp makeDesktopIcon copyDesktopIcons;

        # wine = wineWowPackages.full;
        wine = self.inputs.nix-gaming.packages.x86_64-linux.wine-ge.override {
          monos = [
            sources.mono
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
