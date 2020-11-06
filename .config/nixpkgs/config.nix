with builtins;

let
  packages = import <nixpkgs> { };
  unstable = import <unstable> {};
in {
  allowUnfree = true;
  packageOverrides = pkgs:
    with pkgs; rec {
      libffi-dev = stdenv.mkDerivation rec {
        name = "libffi-dev";
        env = buildEnv { name = name; paths = buildInputs; };
        builder = builtins.toFile "builder.sh" ''
          source $stdenv/setup; ln -s $env $out
        '';
        buildInputs = with pkgs; [
          libffi
          libffi.dev
        ];
      };
      ssl-lib = stdenv.mkDerivation rec {
        name = "ssl-lib";
        env = buildEnv { name = name; paths = buildInputs; };
        builder = builtins.toFile "builder.sh" ''
          source $stdenv/setup; ln -s $env $out
        '';
        buildInputs = with pkgs; [
          libressl.out
        ];
    };
  };
} 
