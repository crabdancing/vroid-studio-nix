{
  description = "A Nix flake for Vroid Studio";

  inputs.erosanix.url = "github:emmanuelrosa/erosanix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  nix-gaming.url = "github:fufexan/nix-gaming";

  outputs = {
    self,
    nixpkgs,
    erosanix,
    nix-gaming,
    ...
  }: {
    packages.x86_64-linux = let
      pkgs = import "${nixpkgs}" {
        system = "x86_64-linux";
      };
    in
      with (pkgs // erosanix.packages.x86_64-linux // erosanix.lib.x86_64-linux); {
        default = self.packages.x86_64-linux.vroid-studio;

        vroid-studio = pkgs.callPackage ./vroid-studio.nix {
          inherit self;
          inherit mkWindowsApp makeDesktopIcon copyDesktopIcons;

          wine = wineWowPackages.full;
        };
      };

    apps.x86_64-linux.vroid-studio = {
      type = "app";
      program = "${self.packages.x86_64-linux.vroid-studio}/bin/vroid-studio";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.vroid-studio;
  };
}
