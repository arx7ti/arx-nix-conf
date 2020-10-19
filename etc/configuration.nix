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
      ./cachix.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    kernel.sysctl = {
      "net.ipv6.conf.all.disable_ipv6" = 1;
      "net.ipv6.conf.default.disable_ipv6" = 1;
      "net.ipv6.conf.lo.disable_ipv6" = 1;
    };
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    extraModprobeConfig = ''
      options kvm ignore_msrs=1
    '';
    #initrd.availableKernelModules = [ "8821ce" ];
    #initrd.kernelModules = [ "8821ce" ];
    kernelModules = [ "nvidia-uvm" ];
    extraModulePackages = with config.boot.kernelPackages; [
      nvidia_x11
      # rtl8821ce
      # tp_smapi
    ];
    cleanTmpDir = true;
  };

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  
  # networking.interfaces.enp4s0.useDHCP = true;
  # networking.interfaces.wlp5s0f3u1.useDHCP = true;
  # networking.networkmanager.enable = false;

  networking = {
    hostName = "nixosAir"; # Define your hostname.
    wireless = {
     enable = false; # Enables wireless support via wpa_supplicant.
     # interfaces = [ "???????" ];
     # networks = { "???????" = { psk = "???????"; }; };
    };
    networkmanager = {
      # Enable networkmanager
      enable = true; 
    };
    useDHCP = false;
    interfaces.wlp5s0f3u1.useDHCP = true;
    # firewall.allowedTCPPorts = [ 22 3020 3350 3389 ];
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://:@127.0.0.1:9050/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  time.timeZone = "Europe/Moscow";
  nixpkgs.config.allowUnfree = true;

  fonts = {
    fonts = with pkgs; [
      opensans-ttf
      dejavu_fonts
      corefonts
      powerline-fonts
      iosevka
      paratype-pt-serif
      paratype-pt-sans
      unifont
      emacs-all-the-icons-fonts
      joypixels
      google-fonts
      tor
    ];
    fontconfig = {
      hinting = {
        autohint = false;
        enable = true;
      };
      subpixel.lcdfilter = "default";
      antialias = true;
      penultimate.enable = true;
      defaultFonts = {
        serif = [ "Tinos" ];
        sansSerif = [ "Arimo" ];
        monospace = [ "Iosevka" ];
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim git curl which
    htop ranger
    lm_sensors compton
    unstable.zsh
    unstable.zsh-completions
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
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  systemd.services = {
    nvidia-control-devices = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi";
    };
    tune-usb-autosuspend = {
      description = "Disable USB autosuspend";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Type = "oneshot"; };
      unitConfig.RequiresMountsFor = "/sys";
      script = ''
        echo -1 > /sys/module/usbcore/parameters/autosuspend
      '';
    };
  };

  hardware.opengl.driSupport32Bit = true;
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };

  powerManagement.enable = true;

  # Enable the X11 windowing system.
  services = {
    tor = {
      enable = true;
      client.enable = true;
    };
    xserver = {
      enable = true;
      autorun = true;
      layout = "us,ru";
      videoDrivers = [ "nvidia" ];
      # services.xserver.xkbOptions = "eurosign:e";

      # Enable touchpad support.
      # services.xserver.libinput.enable = true;

      # Enable the KDE Desktop Environment.
      displayManager.startx.enable = true;
      desktopManager.plasma5.enable = false;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.arxnovena = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" "docker" ]; # Enable ‘sudo’ for the user.
    group = "users";
    home = "/home/arxnovena";
    uid = 1000;
    shell = unstable.zsh;
  };

  nix.sandboxPaths = [ "/dev/dri/card0" "/dev/dri/card1"  "/dev/dri/renderD128"  "/dev/dri/renderD129" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}

