# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
	unstable = import <unstable> {};
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
	loader = {
		systemd-boot.enable = true;
		efi.canTouchEfiVariables = true;
	};
	kernelModules = ["nvidia-uvm"];
	extraModulePackages = with config.boot.kernelPackages; [
	  nvidia_x11
	];
  };

  nixpkgs.config = { allowUnfree = true; };

  networking.hostName = "nixosAir"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp4s0.useDHCP = true;
  # networking.interfaces.wlp5s0f3u5.useDHCP = true;
  networking.networkmanager.enable = true;

  fonts = {
    fonts = with pkgs; [
      corefonts
      dejavu_fonts
      opensans-ttf
      unifont
      google-fonts
      joypixels
      paratype-pt-serif
      paratype-pt-sans
      powerline-fonts
      iosevka
      emacs-all-the-icons-fonts
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Tinos" ];
        sansSerif = [ "Arimo" ];
        monospace = [ "Iosevka" ];
      };
    };
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     nut
     usbutils
     wget vim which
     htop curl git
     pciutils
     unstable.zsh unstable.zsh-completions
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.authorizedKeysFiles = ["~/.ssh/id_ed25519"];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;
  power.ups = {
    enable = false;
    # mode = "standalone";
    # ups = {
    #   ups = {
    #     driver = "usbhid-ups";
    #     port = "auto"; 
    #   };
    # };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver = { 
    enable = true;
    autorun = true;
    layout = "us,ru";
    xkbOptions = "lv3:ralt_switch, grp_led:caps, caps:super";
    videoDrivers = ["nvidia"];
    displayManager.startx.enable = true;
    desktopManager.plasma5.enable = false;
    config = pkgs.lib.mkForce ''
    Section "ServerLayout"
        Identifier     "Layout[all]"
        Screen      0  "Screen-nvidia[1]" 0 0
        Screen      1  "Screen-nvidia[0]" RightOf "Screen-nvidia[1]"
    EndSection

    Section "Device"
        Identifier     "Device-nvidia[0]"
        Driver         "nvidia"
        BusID          "PCI:8:0:0"
    EndSection

    Section "Device"
        Identifier     "Device-nvidia[1]"
        Driver         "nvidia"
        BusID          "PCI:9:0:0"
    EndSection

    Section "Monitor"
        Identifier     "multihead1"
        Option         "DPMS"
    EndSection

    Section "Monitor"
        Identifier     "multihead2"
        Option         "DPMS"
    EndSection

    Section "Screen"
        Identifier     "Screen-nvidia[0]"
        Device         "Device-nvidia[0]"
        Monitor        "multihead2"
    EndSection

    Section "Screen"
        Identifier     "Screen-nvidia[1]"
        Device         "Device-nvidia[1]"
        Monitor        "multihead1"
    EndSection
    '';
    # xrandrHeads = ["HDMI-0" "HDMI-1"];
    # deviceSection = ''
    #   BusID "PCI:8:0:0"
    # '';
    # screenSection = ''
    # Option "Screen-nvidia[0]"
    # '';
    # extraConfig = ''
    # Section "Device"
    #   Identifier "Device-nvidia[1]"
    #   Driver "nvidia"
    #   BusID "PCI:9:0:0"
    #   Option "monitor-HDMI-0" "multihead1"
    #   Option "monitor-HDMI-0-1" "multihead2"
    # EndSection

    # Section "Screen"
    #   Identifier "Screen-nvidia[1]"
    #   Device "Device-nvidia[1]"
    # EndSection
    # '';
  };

services.postgresql = {
    enable = true;
    package = pkgs.postgresql_10;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE admin WITH LOGIN PASSWORD 'admin' CREATEDB;
      CREATE DATABASE deepnilm;
      GRANT ALL PRIVILEGES ON DATABASE deepnilm TO admin;
    '';
  };

  systemd.services.nvidia-control-devices = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi";
  };

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.arx7ti = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "nut" ]; # Enable ‘sudo’ for the user.
    group = "users";
    home = "/home/arx7ti";
    uid = 1000;
    shell = unstable.zsh;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}

