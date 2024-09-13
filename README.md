# Status

Working. No known problems found.

# How it works

- Builds proton-ge + mono from [nix-gaming](https://github.com/fufexan/nix-gaming) repo, since stock wine does not handle hardware acceleration correctly.
- Uses nixpkgs' wine-mono.
- Builds semi-isolated Wine environment with [mkwindowsapp](https://github.com/emmanuelrosa/erosanix/tree/master/pkgs/mkwindowsapp).
- nix run phase:
  - Runs installation wizard with `/silent` flag
  - builds the fs layer on the fly
  - optionally copies config(s) over
  - launches VRoid Studio


# How to use



### Initialize with defaults (which can be changed) via UI/imperative editing:

`nix run github:crabdancing/vroid-studio-nix`

This sets dark mode by default.


### Normal run:

`nix run github:crabdancing/vroid-studio-nix#vroidStudioWithoutConf`


### Example of initializing with locked (reset on start) defaults:

`nix run github:crabdancing/vroid-studio-nix#vroidStudioBigUI`

This sets the GUI size to 150% instead of 100%. The application tries to normalize this to supported parameters each time the settings UI is opened, thus it is necessary to overwrite the config on reload in case it has been fixed. While it's slightly clunky/awkward, this config works, and is useful for accessibility purposes & on large monitors. I'm not entirely sure why upstream decided to try to lock out this functionality, and am forced to consider that they might not have had a reason.

### Example of custom config:

```nix
vroid-studio-nix.packages.x86_64-linux.baseVRStudio.override {
  # optionally generate this from a Nix expression if you need :3
  # or just put it in your config git repo
  editorConfig = ./myconfig.xml;
  # do this if you're worried about losing the config for some reason
  # forceConfig = true;
};
```

This assumes you've already put the flake in your inputs.