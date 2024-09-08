{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    gradle2nix = {
      url = "github:tnichols217/gradle2nix/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
      pkgs = import inputs.nixpkgs {inherit system config;};

      buildToolsVersion = "34.0.0";
      ndkVersion = "25.1.8937393";

      androidPackages = pkgs.androidenv.composeAndroidPackages {
        cmdLineToolsVersion = "8.0";
        toolsVersion = "26.1.1";
        platformToolsVersion = "34.0.4";
        buildToolsVersions = [buildToolsVersion];
        includeEmulator = false;
        emulatorVersion = "30.3.4";
        platformVersions = ["34"];
        includeSources = false;
        includeSystemImages = false;
        systemImageTypes = ["google_apis_playstore"];
        abiVersions = ["armeabi-v7a" "arm64-v8a"];
        cmakeVersions = ["3.10.2" "3.22.1"];
        includeNDK = false;
        ndkVersions = [ndkVersion];
        useGoogleAPIs = false;
        useGoogleTVAddOns = false;
        includeExtras = ["extras;google;gcm"];
      };
      androidSdk = androidPackages.androidsdk;
      extraGradleFlags = [ "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2" ];
    in {
      packages = rec {
        scrcpy = inputs.gradle2nix.builders.${system}.buildGradlePackage {
          inherit extraGradleFlags;
          pname = "scrcpy";
          version = "1.0";
          src = ./.; # fetch from github
          lockFile = ./gradle.lock;
          ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk";
          nativeBuildInputs = [
            androidSdk
          ];
          installPhase = ''mkdir -p $out; cp -r server/build/outputs/apk/*/*.apk $out'';
        };
        default = scrcpy;
      };
      devShells = rec {
        gradle = pkgs.mkShell {
          buildInputs = [
            androidSdk
            pkgs.gradle
          ];

          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          # Override the aapt2 that gradle uses with the nix-shipped version
          GRADLE_OPTS = pkgs.lib.strings.concatStringsSep " " extraGradleFlags;
          UPDATE_LOCK = ''nix run github:tnichols217/gradle2nix/v2 -- -t :server:build -- $GRADLE_OPTS'';
        };
        default = gradle;
      };
    });
}

