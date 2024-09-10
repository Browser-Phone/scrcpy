{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    gradle2nix = {
      url = "github:tadfisher/gradle2nix/v2";
    };
    scrcpy = {
      url = "github:Genymobile/scrcpy";
      flake = false;
    };
  };

  outputs = {...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
      pkgs = import inputs.nixpkgs {inherit system config;};

      platformVersions = "34";
      buildToolsVersion = "${platformVersions}.0.0";
      platformToolsVersion = "${platformVersions}.0.4";

      androidPackages = pkgs.androidenv.composeAndroidPackages {
        inherit platformToolsVersion;
        toolsVersion = null;
        cmdLineToolsVersion = "8.0";
        buildToolsVersions = [buildToolsVersion];
        platformVersions = [platformVersions];
      };
      extraGradleFlags = [ "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/${buildToolsVersion}/aapt2" ];
      overrideGradleFlags = drv: drv.overrideAttrs (final: prev: (prev // {
        gradleFlags = (pkgs.lib.lists.drop 1 prev.gradleFlags) ++ extraGradleFlags;
      }));
      buildGradlePackage = args: overrideGradleFlags (inputs.gradle2nix.builders.${system}.buildGradlePackage args);
      androidSdk = androidPackages.androidsdk;
    in {
      packages = rec {
        scrcpy = pkgs.callPackage ./nix/scrcpy.nix {
          inherit pkgs buildGradlePackage androidSdk;
          scrcpy = inputs.scrcpy;
        };
        default = scrcpy;
      };
      devShells = rec {
        gradle = pkgs.callPackage ./nix/shell.nix {
          inherit pkgs androidSdk extraGradleFlags system overrideGradleFlags;
          gradle2nix = inputs.gradle2nix.packages.${system}.gradle2nix;
        };
        default = gradle;
      };
      apps = {
        update-lock = pkgs.callPackage ./nix/update-lock.nix {
          inherit pkgs androidSdk  extraGradleFlags system overrideGradleFlags;
          inherit (inputs) flake-utils scrcpy;
          gradle2nix = inputs.gradle2nix.packages.${system}.gradle2nix;
        };
      };
      formatter = pkgs.alejandra;
    });
}

