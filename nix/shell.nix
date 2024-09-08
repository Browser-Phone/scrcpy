{ androidSdk, pkgs, extraGradleFlags, overrideGradleFlags, gradle2nix, system }:
pkgs.mkShell rec {
  buildInputs = [
    androidSdk
    pkgs.gradle
    gradle2nix
  ];

  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  # Override the aapt2 that gradle uses with the nix-shipped version
  GRADLE_OPTS = pkgs.lib.strings.concatStringsSep " " extraGradleFlags;
  UPDATE_LOCK = ''gradle2nix -t :server:build -- ${GRADLE_OPTS}'';
}