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
in
pkgs.mkShell {
  buildInputs = (with pkgs; [
    python3
    qt5.full
    twitterBootstrap
  ]) ++
  (with pkgs.python37Packages; [
    flask
    psycopg2
    sqlalchemy
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
    flask-bootstrap
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
    TMPDIR=./.tmp pip install --cache-dir=./.tmp torchvision 
    pip install -r requirements.txt
  '';
  XDG_DATA_DIRS = "${pkgs.qt5.full}:$XDG_DATA_DIRS";
  LD_LIBRARY_PATH = "${pkgs.stdenv.lib.makeLibraryPath libs}";
  CUDA_PATH = "${ pkgs.cudatoolkit_10_1 }";
}
