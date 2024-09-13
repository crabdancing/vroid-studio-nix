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
  forceConfig ? true,
}: let
  # The default settings used if user doesn't already have a settings file.
  # Tabs are disabled because they lead to UI issues when using Wine.
  # defaultSettings = ./SumatraPDF-settings.txt;
  # This registry file sets winebrowser (xdg-open) as the default handler for
  # text files, instead of Wine's notepad.
  # Selecting "Settings -> Advanced Options" should then use xdg-open to open the SumatraPDF config file.
  txtReg = ./txt.reg;
in
  mkWindowsApp rec {
    inherit wine;
    # wine = self.inputs.nix-gaming.packages.${system}.wine-ge;

    pname = "vroid-studio";
    version = "1.29.2";

    src = builtins.fetchurl {
      url = "https://download.vroid.com/dist/EYKGmv7H1S/VRoidStudio-v${version}-win.exe";
      # sha256 = lib.fakeHash;
      sha256 = "sha256:17pqpb2zhv5zxf2f1mwhr1rqys3inmrwb2z1g1ixl2h53kvlcchc";
    };

    # In most cases, you'll either be using an .exe or .zip as the src.
    # Even in the case of a .zip, you probably want to unpack with the launcher script.
    dontUnpack = true;

    # You need to set the WINEARCH, which can be either "win32" or "win64".
    # Note that the wine package you choose must be compatible with the Wine architecture.
    wineArch = "win64";

    # Sometimes it can take a while to install an application to generate an app layer.
    # `enableInstallNotification`, which is set to true by default, uses notify-send
    # to generate a system notification so that the user is aware that something is happening.
    # There are two notifications: one before the app installation and one after.
    # The notification will attempt to use the app's icon, if it can find it. And will fallback
    # to hard-coded icons if needed.
    # If an app installs quickly, these notifications can actually be distracting.
    # In such a case, it's better to set this option to false.
    # This package doesn't benefit from the notifications, but I've explicitly enabled them
    # for demonstration purposes.
    enableInstallNotification = true;

    # MAJOR GOTCHA: `users` directory is created as `Users` in Windows, but in wine is lower!
    fileMap = {
      "$HOME/.local/share/${pname}/local-low" = "drive_c/users/$USER/AppData/LocalLow/pixiv/VRoid Studio";
      # "$HOME/Documents" = "drive_c/Users/$USER/Documents";
    };

    # By default, `fileMap` is applied right before running the app and is cleaned up after the app terminates. If the following option is set to "true", then `fileMap` is also applied prior to `winAppInstall`. This is set to "false" by default.
    fileMapDuringAppInstall = false;

    # By default `mkWindowsApp` doesn't persist registry changes made during runtime. Therefore, if an app uses the registry then set this to "true". The registry files are saved to `$HOME/.local/share/mkWindowsApp/$pname/`.
    persistRegistry = false;

    # By default mkWindowsApp creates ephemeral (temporary) WINEPREFIX(es).
    # Setting persistRuntimeLayer to true causes mkWindowsApp to retain the WINEPREFIX, for the short term.
    # This option is designed for apps which can't have their automatic updates disabled.
    # It allows package maintainers to not have to constantly update their mkWindowsApp packages.
    # It is NOT meant for long-term persistance; If the Windows or App layers change, the Runtime layer will be discarded.
    persistRuntimeLayer = false;

    # The method used to calculate the input hashes for the layers.
    # This should be set to "store-path", which is the strictest and most reproduceable method. But it results in many rebuilds of the layers since the slightest change to the package inputs will change the input hashes.
    # An alternative is "version" which is a relaxed method and results in fewer rebuilds but is less reproduceable. If you are considering using "version", contact me first. There may be a better way.
    inputHashMethod = "store-path";

    nativeBuildInputs = [unzip copyDesktopItems copyDesktopIcons];

    # This code will become part of the launcher script.
    # It will execute if the application needs to be installed,
    # which would happen either if the needed app layer doesn't exist,
    # or for some reason the needed Windows layer is missing, which would
    # invalidate the app layer.
    # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
    # and wine, winetricks, and cabextract are in the environment.
    # d="$WINEPREFIX/drive_c/${pname}"
    # config_dir="$HOME/.config/vroid-studio"

    # mkdir -p "$d"
    # unzip ${src} -d "$d"

    # mkdir -p "$config_dir"

    winAppInstall = ''
      winetricks -q dxvk
      $WINE ${src} /silent
      regedit ${txtReg}
    '';
    # cp -v -n "${defaultSettings}" "$config_dir/SumatraPDF-settings.txt"
    # chmod ug+w "$config_dir/SumatraPDF-settings.txt"

    # This code runs before winAppRun, but only for the first instance.
    # Therefore, if the app is already running, winAppRun will not execute.
    # Use this to do any setup prior to running the app.
    winAppPreRun = ''
    '';

    # This code will become part of the launcher script.
    # It will execute after winAppInstall and winAppPreRun (if needed),
    # to run the application.
    # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
    # and wine, winetricks, and cabextract are in the environment.
    # Command line arguments are in $ARGS, not $@
    # DO NOT BLOCK. For example, don't run: wineserver -w
    winAppRun = ''
      cp ${self + "/editoroption.xml"} "$WINEPREFIX/drive_c/users/nikoru/AppData/LocalLow/pixiv/VRoid Studio/preferences/editoroption.xml" -v
      wine "$WINEPREFIX/drive_c/users/$USER/AppData/Local/Programs/VRoidStudio/${version}/VRoidStudio.exe" "$ARGS"
    '';

    # This code will run after winAppRun, but only for the first instance.
    # Therefore, if the app was already running, winAppPostRun will not execute.
    # In other words, winAppPostRun is only executed if winAppPreRun is executed.
    # Use this to do any cleanup after the app has terminated
    winAppPostRun = "";

    # This is a normal mkDerivation installPhase, with some caveats.
    # The launcher script will be installed at $out/bin/.launcher
    # DO NOT DELETE OR RENAME the launcher. Instead, link to it as shown.
    installPhase = ''
      runHook preInstall

      ln -s $out/bin/.launcher $out/bin/${pname}

      runHook postInstall
    '';

    desktopItems = let
      # mimeTypes = [
      #   "application/pdf"
      #   "application/epub+zip"
      #   "application/x-mobipocket-ebook"
      #   "application/vnd.amazon.mobi8-ebook"
      #   "application/x-zip-compressed-fb2"
      #   "application/x-cbt"
      #   "application/x-cb7"
      #   "application/x-7z-compressed"
      #   "application/vnd.rar"
      #   "application/x-tar"
      #   "application/zip"
      #   "image/vnd.djvu"
      #   "image/vnd.djvu+multipage"
      #   "application/vnd.ms-xpsdocument"
      #   "application/oxps"
      #   "image/jpeg"
      #   "image/png"
      #   "image/gif"
      #   "image/webp"
      #   "image/tiff"
      #   "image/tiff-multipage"
      #   "image/x-tga"
      #   "image/bmp"
      #   "image/x-dib"
      # ];
    in [
      (makeDesktopItem {
        # inherit mimeTypes;

        name = pname;
        exec = pname;
        icon = pname;
        desktopName = "VRoid Studio";
        genericName = "3D CAD software for making anime figures";
        categories = ["Graphics" "Viewer"];
      })
    ];

    # desktopIcon = makeDesktopIcon {
    #   name = "vroid-studio";

    #   src = fetchurl {
    #     url = "https://vroid-studio.com/images/moi001.png";
    #     sha256 = "sha256-c+B847cKvtp5ZUvpoJ7JvgKRH95gdTngS6jyBxkXBvA=";
    #   };
    # };

    meta = with lib; {
      description = "VRoid Studio";
      homepage = "https://vroid.com/en/studio";
      license = licenses.unfree;
      maintainers = with maintainers; [];
      platforms = ["x86_64-linux"];
    };
  }
