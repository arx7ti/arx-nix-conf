{ config, pkgs, ... }:
let
  aliases = {
    doom = "~/.emacs.d/bin/doom";
  };
	unstable = import <unstable> {};
  kbdLayout = "us,ru";
  kbdVariant = ",";
  xinit = ''
    # eval `dbus-launch --auto-syntax`
    xhost +SI:localuser:$USER
    xrdb ~/.Xresources &
    xset r rate 300 60

    setxkbmap -layout ${kbdLayout} -variant ${kbdVariant} -option lv3:ralt_switch -option grp_led:caps -option caps:super -option grp:shifts_toggle

    # feh --bg-scale ~/.config/wall.jpg &
    # xcalib ~/.config/Lenovo_Ideapad_nixosAir.icm &
    # xinput set-prop 10 'libinput Accel Speed' -0.2
  '';
in {
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  services = {
    lorri.enable = true;
    unclutter = {
      enable = true;
      extraOptions = [ "ignore-scrolling" ];
    };
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.nordic;
      name = "Nordic";
    };
    iconTheme = {
      package = pkgs.paper-icon-theme;
      name = "Paper";
    };
  };

	nixpkgs.config.allowUnfree = true;

  fonts.fontconfig = { enable = true; };

	xsession  = {
		enable = true;
    pointerCursor = {
      package = pkgs.numix-cursor-theme;
      name = "Numix-Cursor-Light";
      size = 28;
    };
    windowManager.command = "dbus-launch --sh-syntax --exit-with-session emacs --eval '(exwm-init)'";
    initExtra = xinit;
	};
	programs = {
    direnv.enableNixDirenvIntegration = true;
		# Let Home Manager install and manage itself.
		home-manager.enable = true;
		emacs = {
			enable = true;
			package = unstable.emacs;
			extraPackages = (epkgs: with epkgs; [
				pdf-tools jupyter exwm elpy
			] ++ (with unstable; [libvterm cmake gnumake gcc]));
		};
    zsh = {
      enable = true;
      autocd = true;
      dotDir = ".config/zsh";
      enableCompletion = true;
      enableAutosuggestions = true;
      defaultKeymap = "viins";
      shellAliases = aliases;
      initExtraBeforeCompInit = ''
        fpath=(~/.config/zsh/completion $fpath)
      '';
      plugins = [
        {
          name = "sfz";
          src = builtins.fetchGit {
            url = "https://github.com/teu5us/sfz-prompt.zsh";
          };
        }
        {
          name = "fzf-tab";
          src =
            builtins.fetchGit { url = "https://github.com/Aloxaf/fzf-tab"; };
        }
        {
          name = "zsh-autosuggestions";
          src = builtins.fetchGit {
            url = "https://github.com/zsh-users/zsh-autosuggestions";
          };
        }
        {
          name = "fast-syntax-highlighting";
          src = builtins.fetchGit {
            url = "https://github.com/desyncr/fast-syntax-highlighting";
          };
        }
      ];
      initExtra = ''
        bindkey '^F' autosuggest-accept
        bindkey '^G' toggle-fzf-tab
        v () {
          nvim $* && rm .nvimlog
        }
        autoload -Uz v

        # indicate mode by cursor shape
        zle-keymap-select () {
        if [ $KEYMAP = vicmd ]; then
            printf "\033[2 q"
        else
            printf "\033[6 q"
        fi
        }
        zle-line-init () {
            zle -K viins
            printf "\033[6 q"
        }
        zle-line-finish () {
            printf "\033[2 q"
        }
        zle -N zle-keymap-select
        zle -N zle-line-init
        zle -N zle-line-finish
      '';
    };
	};
	home = {
		packages = with pkgs; [
      xorg.xev
			pandoc
			sqlite
			chromium
      firefox
	    texlive.combined.scheme-full
      libvterm
      direnv
      tmux tmate
      unstable.tdesktop
      cachix
      glmark2
      stress
      iotop
      cmake
      gnumake
      pciutils
      nix-prefetch-git
		];
    file = {
      ".xinitrc".text = ''
        $HOME/.xsession
      '';
      ".agignore".source = ./home/agignore;
      # vim mode
      ".inputrc".text = ''
        set editing-mode vi
        set keymap vi-command
      '';
      ".tmate.conf".source = ./home/tmate.conf;
      ".tmux.conf".source = ./home/tmux.conf;
      # ".config/fontconfig/fonts.conf".source =
      #   ./home/config/fontconfig/fonts.conf;
    };
		stateVersion = "20.03";
	};
}
