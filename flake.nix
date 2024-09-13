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

      mono = pkgs.fetchurl rec {
        version = "8.1.0";
        url = "https://dl.winehq.org/wine/wine-mono/${version}/wine-mono-${version}-x86.msi";
        hash = "sha256-DtPsUzrvebLzEhVZMc97EIAAmsDFtMK8/rZ4rJSOCBA=";
      };
      wine = self.inputs.nix-gaming.packages.x86_64-linux.wine-ge.override {
        monos = [
          mono
        ];
      };
      baseVRoidStudio = pkgs.callPackage ./vroid-studio.nix {
        inherit self;
        inherit (erosanix.lib.x86_64-linux) mkWindowsApp makeDesktopIcon copyDesktopIcons;
        inherit wine;
      };
    in {
      default = baseVRoidStudio;

      inherit wine;
      inherit baseVRoidStudio;

      vroidStudio = baseVRoidStudio.override {
        editorConfig = ./editoroption.xml;
        forceConfig = false;
      };
      vroidStudioBigUI = baseVRoidStudio.override {
        editorConfig = ./editoroption-bigui.xml;
        forceConfig = true;
      };
    };

    apps.x86_64-linux.vroidStudio = {
      type = "app";
      program = "${self.packages.x86_64-linux.vroidStudio}/bin/vroid-studio";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.vroidStudio;
  };
}
