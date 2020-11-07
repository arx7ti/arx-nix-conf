{ pkgs ? import <nixpkgs> { } }:
let
  venvDir = "./.venv-nix";
  libs = [
    pkgs.stdenv.cc.cc.lib
    pkgs.xorg.libX11
    pkgs.ncurses5
    pkgs.linuxPackages.nvidia_x11
    pkgs.libGL
    pkgs.libzip
    pkgs.glib
  ];
  hy-lang = pkgs.python37.pkgs.buildPythonPackage rec {
    pname = "hy";
    version = "0.16.0";
    src = pkgs.python37.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "2dff2bf9fc4bea6648b8ec8022c4d655e9cc63f2b1588706f737cf782f1a9802";
    };
    doCheck = false;
    buildInputs = with pkgs.python37Packages; [
      tox
    ];
    propagatedBuildInputs = with pkgs.python37Packages; [
      appdirs
      astor
      clint
      colorama
      fastentrypoints
      funcparserlib
      rply
    ];
  };
  jedhy = pkgs.python37.pkgs.buildPythonPackage rec {
    pname = "jedhy";
    version = "1";
    src = pkgs.python37.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "0964b4a159aef450bc4783faa0b37114eb3c9f2eaa69e4b1ed7856ed398d15ab";
    };
    doCheck = false;
    propagatedBuildInputs = with pkgs.python37Packages; [
      toolz
      hy-lang
    ];
  };
in
pkgs.mkShell {
  buildInputs = (with pkgs; [
    python3
    qt5.full
  ]) ++
  (with pkgs.python37Packages; [
    black
    pandas
    sklearn-deap
    matplotlib
    seaborn
    tqdm
    requests
    ipykernel
    jupyter
    jupyterlab
    geopandas
  ]) ++ (with pkgs.pkgs; [
    (python3.withPackages
      (pypkgs: with pypkgs; [
        hy-lang
        jedhy
      ]))
  ]);

  nativeBuildInputs = [ pkgs.cudatoolkit_10_1 ];

  shellHook = ''
    if [ -d "${venvDir}" ]; then
      echo "Virtualenv '${venvDir}' already exists"
    else
      echo "Creating virtualenv '${venvDir}'"
      ${pkgs.python3Packages.python.interpreter} -m venv "${venvDir}"
    fi
    source "${venvDir}/bin/activate"
    pip install --upgrade pip
    # TMPDIR=./.tmp pip install --cache-dir=./.tmp xgboost torchvision calysto-hy
  '';
  XDG_DATA_DIRS = "${pkgs.qt5.full}:$XDG_DATA_DIRS";
  LD_LIBRARY_PATH = "${pkgs.stdenv.lib.makeLibraryPath libs}";
  CUDA_PATH = "${ pkgs.cudatoolkit_10_1 }";
}
