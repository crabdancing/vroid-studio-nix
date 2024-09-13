{
  stdenv,
  lib,
  mkWindowsApp,
  wine,
  fetchurl,
  makeDesktopItem,
  makeDesktopIcon, # This comes with erosanix. It's a handy way to generate desktop icons.
  copyDesktopItems,
  copyDesktopIcons, # This comes with erosanix. It's a handy way to generate desktop icons.
  unzip,
  system,
  self,
  pkgs,
  editorConfig ? null,
  forceConfig ? false,
}: let
  # This registry file sets winebrowser (xdg-open) as the default handler for
  # text files, instead of Wine's notepad.
  txtReg = ./txt.reg;
  version = "1.29.2";
  pname = "vroid-studio";

  src = builtins.fetchurl {
    url = "https://download.vroid.com/dist/EYKGmv7H1S/VRoidStudio-v${version}-win.exe";
    sha256 = "sha256:17pqpb2zhv5zxf2f1mwhr1rqys3inmrwb2z1g1ixl2h53kvlcchc";
  };
  # iconConvTools = pkgs.callPackage (self.inputs.nixpkgs + "/pkgs/build-support/icon-conv-tools") {};
  # icon = pkgs.runCommand "${pname}-icon" {} ''
  #   echo ${iconConvTools}/bin/extractWinRscIconsToStdFreeDesktopDir.sh ${src} \
  #     '[^\.]+\.exe_[0-9]+_[0-9]+_[0-9]+_[0-9]+_([0-9]+x[0-9]+)x[0-9]+\.png' \
  #     '\1' \
  #     '([^\.]+).+' \
  #     ${pname} \
  #     "$out"
  # '';
in
  mkWindowsApp rec {
    inherit wine src version pname;

    dontUnpack = true;

    wineArch = "win64";
    enableInstallNotification = true;

    # MAJOR GOTCHA: `users` directory is created as `Users` in Windows, but in wine is lower!
    fileMap = {
      "$HOME/.local/share/${pname}/local-low" = "drive_c/users/$USER/AppData/LocalLow/pixiv/VRoid Studio";
      # "$HOME/Documents" = "drive_c/Users/$USER/Documents";
    };

    fileMapDuringAppInstall = false;
    persistRegistry = false;
    persistRuntimeLayer = false;
    inputHashMethod = "store-path";

    nativeBuildInputs = [unzip copyDesktopItems copyDesktopIcons];

    winAppInstall = ''
      winetricks -q dxvk
      $WINE ${src} /silent
      regedit ${txtReg}
    '';
    winAppPreRun = ''
    '';

    winAppRun =
      ''
        state_dir="$HOME/.local/share/vroid-studio/local-low"
        mkdir -p "$state_dir"
      ''
      + lib.optionalString (editorConfig != null)
      (
        let
          # forceConfig removes -n flag, causing cp to override config on launch
          # this is useful if you want to prevent VRoid from overwriting your config
          flags = ["-v"] ++ lib.optionals (!forceConfig) ["-n"];
        in ''
          cp ${lib.concatStringsSep " " flags} "${./editoroption.xml}" "$state_dir/preferences/editoroption.xml"
        ''
      )
      + ''
        wine "$WINEPREFIX/drive_c/users/$USER/AppData/Local/Programs/VRoidStudio/${version}/VRoidStudio.exe" "$ARGS"
      '';

    winAppPostRun = "";

    installPhase = ''
      runHook preInstall
      ln -s $out/bin/.launcher $out/bin/${pname}
      runHook postInstall
    '';

    desktopItems = let
      mimeTypes = [
        "application/x-vrm"
      ];
    in [
      (makeDesktopItem {
        inherit mimeTypes;

        name = pname;
        exec = pname;
        icon = pname;
        desktopName = "VRoid Studio";
        genericName = "3D CAD software for making anime figures";
        categories = ["Graphics" "Viewer"];
      })
    ];

    desktopIcon = makeDesktopIcon {
      name = "vroid-studio";
      src = ./vroid_studio.png;
    };

    meta = with lib; {
      description = "VRoid Studio";
      homepage = "https://vroid.com/en/studio";
      license = licenses.unfree;
      maintainers = with maintainers; [];
      platforms = ["x86_64-linux"];
    };
  }
