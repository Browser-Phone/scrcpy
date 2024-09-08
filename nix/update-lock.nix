{ pkgs, flake-utils, androidSdk, gradle2nix, extraGradleFlags, system, scrcpy, overrideGradleFlags }:
flake-utils.lib.mkApp {
  drv = pkgs.writeShellApplication {
    name = "update-lock";
    runtimeInputs = [
      androidSdk
      pkgs.gradle
      gradle2nix
    ];
    text = ''
      export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk";
      OUTDIR=$(pwd)
      TMPDIR=$(mktemp -d)
      cd "$TMPDIR"
      cp --no-preserve=mode -r ${scrcpy}/* ./
      gradle2nix -t :server:build -o "$OUTDIR" -- ${pkgs.lib.strings.concatStringsSep " " extraGradleFlags};
      rm -rf "$TMPDIR"
    '';
  };
}