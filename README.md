# Status

Working. No known problems found.

# How it works

- Builds proton-ge + mono from [nix-gaming](https://github.com/fufexan/nix-gaming) repo, since stock wine does not handle hardware acceleration correctly.
- Uses nixpkgs' wine-mono.
- Builds semi-isolated Wine environment with [mkwindowsapp](https://github.com/emmanuelrosa/erosanix/tree/master/pkgs/mkwindowsapp).
- Runs installation wizard during nix run phase, builds the container on the fly, and then launches VRoid Studio.