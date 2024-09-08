{ buildGradlePackage, scrcpy, androidSdk, pkgs, ... }:
buildGradlePackage {
  pname = "scrcpy";
  version = "1.0";
  src = scrcpy;
  lockFile = ../gradle.lock;
  ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk";
  nativeBuildInputs = [
    androidSdk
  ];
  preBuild = "set -x; env;";
  installPhase = ''mkdir -p $out; cp -r server/build/outputs/apk/*/*.apk $out'';
}