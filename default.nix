{ pkgs ? import <nixpkgs> { } }:
let
  venvDir = "./.venv-nix";

  # These are necessary for taichi at runtime.
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
    # pip install -r ./requirements.txt
  '';

  LD_LIBRARY_PATH = "${pkgs.stdenv.lib.makeLibraryPath libs}";
  CUDA_PATH = "${ pkgs.cudatoolkit_10_1 }";
}
