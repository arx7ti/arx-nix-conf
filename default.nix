{ pkgs ? import (builtins.fetchGit {
  url = "https://github.com/nixos/nixpkgs-channels";
  ref = "refs/heads/nixos-unstable";
  rev = "a45f68ccac476dc37ddf294530538f2f2cce5a92";
}) { } }:

with pkgs;

let
  stable = import <nixpkgs> {};
  pycocotools = pkgs.python37.pkgs.buildPythonPackage rec {
    pname = "pycocotools";
    version = "2.0.1";

    src = pkgs.python37.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "1c06e73a85ed9874c1174d47064524b9fb2759b95a6997437775652f20c1711f";
    };

    doCheck = false;

    buildInputs = with pkgs.python37Packages; [
      pytest
      pytestrunner
      pytest-flakes
      cython
      matplotlib
    ];
  };
  the-torchvision = pkgs.python37.pkgs.buildPythonPackage rec {
    pname = "vision";
    version = "v0.6.1";
  
    src = pkgs.fetchFromGitHub {
      owner = "pytorch";
      repo = "${pname}";
      rev = "${version}";
      sha256="0iq8raaxhf0hdsf7ifr7lr2xx6w1a1kq671m9dxhwfgnfjslm0ln";
    };
  
    doCheck = false;
    dontUseCmakeConfigure = true;
  
    nativeBuildInputs = with pkgs; [
      cmake which utillinux ninja cudaPackages.cudatoolkit_10_1 cudnn_cudatoolkit_10_1
    ];
    propagatedBuildInputs = (with pkgs.python37Packages; [
      six
      numpy
      pillow
      pytorchWithCuda
      scipy
    ]) ++ (with pkgs; [ linuxPackages.nvidia_x11 ]);
  
    FORCE_CUDA = "1";

    cmakeFlags = [
      "-DCMAKE_PREFIX_PATH=${pkgs.python37Packages.pytorchWithCuda}/lib/python3.7/site-packages/torch"
      "-DCMAKE_PREFIX_PATH=${pkgs.cudaPackages.cudatoolkit_10_1}/lib"
      "-DCMAKE_BUILD_TYPE=Release"
      "-DWITH_CUDA=ON"
    ];

    preConfigurePhase = ''
      export CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit_10_1}"
      export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib"
      export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
      export EXTRA_CCFLAGS="-I/usr/include"
    '';
  };
in
ccacheStdenv.mkDerivation rec {
  name = "zu-pytorch";
  # Mandatory boilerplate for buildable env
  # this boilerplate is courtesy of Asko Soukka
  env = buildEnv { name = name; paths = buildInputs; };
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup; ln -s $env $out
  '';
  buildInputs = (with pkgs; [
    git
    gitRepo
    gnupg
    autoconf
    curl
    procps
    gnumake
    utillinux
    gperf
    unzip
    cudaPackages.cudatoolkit_10_1
    cudnn_cudatoolkit_10_1
    linuxPackages.nvidia_x11
    libGLU
    freeglut
    zlib
    ncurses5
    stdenv.cc
    binutils
    python37
    python-language-server
  ]) ++
  (with pkgs.xorg; [
    libXi
    libXmu
    libXext
    libX11
    libXv
    libXrandr
  ]) ++
  (with pkgs.python37Packages; [
    ipykernel
    jupyter
    jupyterlab
    matplotlib
    seaborn
    numpy
    pandas
    pycocotools
    pytorchWithCuda
    requests
    tqdm
    scipy
    sklearn-deap
    #(xgboost.overrideAttrs (oldAttrs: {
    #  buildInputs = oldAttrs.buildInputs ++ [ stable.python37Packages.datatable ];
    #}))
    (datatable.overrideAttrs (oldAttrs: rec {
      doCheck = false;
      pythonImportsCheck = [];
    }))
    # the-torchvision
  ]);
  shellHook = ''
    export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit_10_1}
    # export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib:${pkgs.python37Packages.pytorchWithCuda}/lib
    export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    export EXTRA_CCFLAGS="-I/usr/include"
  '';          
}
