{ config, pkgs, lib, ... }:

let
  isLaptop = config.networking.hostName == "thinkpad";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
  nix-flatpak = builtins.fetchTarball "https://github.com/gmodena/nix-flatpak/archive/latest.tar.gz";
in
{
  imports = [
    ./hardware-configuration.nix
    "${home-manager}/nixos"
    "${nix-flatpak}/modules/nixos.nix"
  ];

  networking.hostName = "nixos";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    gnome-console
    gnome-disk-utility
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.user-themes
    gnomeExtensions.app-hider
    gnomeExtensions.rounded-window-corners-reborn
    gnome-system-monitor
    gnome-tweaks
    nautilus
    adw-gtk3
    gamemode
    xdg-user-dirs
    xdg-user-dirs-gtk
    xdg-desktop-portal-gtk
    nerd-fonts.adwaita-mono
    vscode
    epson-201401w
    filen-desktop
    steam-devices-udev-rules
    javaPackages.compiler.openjdk21
  ] ++ lib.optionals isLaptop [
    gnomeExtensions.touchup
  ];

  services.flatpak.packages = [
    "app.zen_browser.zen"
    "org.gnome.TextEditor"
    "org.gnome.Calculator"
    "org.gnome.Decibels"
    "org.gnome.Showtime"
    "org.gnome.Papers"
    "org.gnome.Loupe"
    "org.gnome.FileRoller"
    "org.gnome.NautilusPreviewer"
    "org.gnome.Boxes"
    "org.gnome.SimpleScan"
    "com.github.finefindus.eyedropper"
    "com.github.tchx84.Flatseal"
    "com.valvesoftware.Steam"
    "com.discordapp.Discord"
    "com.vysp3r.ProtonPlus"
    "org.localsend.localsend_app"
    "io.github.Foldex.AdwSteamGtk"
    "io.github.swordpuffin.rewaita"

  ] ++ lib.optionals isLaptop [
    "com.github.flxzt.rnote"
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      timeout = 0;
      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];

    plymouth.enable = true;
    consoleLogLevel = 3;
    initrd.verbose = false;
  };
 
  system = {
    stateVersion = "25.11";
    autoUpgrade = {
      enable = true;
      operation = "switch";
      dates = "daily";
      channel = "https://channels.nixos.org/nixos-25.11";
    };
  };

  nix.gc = { 
    automatic = true; 
    persistent = true; 
    dates = "weekly"; 
    options = "--delete-older-than 7d"; 
  }; 

  networking = {
    networkmanager.enable = true;
    firewall.enable = if isLaptop then true else false;
  };

  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "es_MX.UTF-8";

  console.keyMap = "us-acentos";
  security.rtkit.enable = true;

  virtualisation = {
    containers.enable = true;
    podman.enable = true;
  };

  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xserver = {
      enable = false;
      xkb = {
        layout = "us";
        variant = "intl";
      };
    };

    gnome = {
      core-apps.enable = false;
      evolution-data-server.enable = lib.mkForce false;
      gnome-online-accounts.enable = false;
      rygel.enable = false;
    };

    fprintd.enable = isLaptop;
    fwupd.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.epson-201401w ];
    };

    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # jack.enable = true;
    };

    flatpak = {
      enable = true;
      remotes = lib.mkOptionDefault [{
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }];
    };
  };

  # set a password with ‘passwd’.
  users.users.tez = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "Tez";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  programs = {
    fish = {
      enable = true;
      interactiveShellInit =  ''
        set fish_greeting
        if test "$TERM" != "linux"
          starship init fish | source
        end
      '';
    };
  };

  home-manager.users.tez = { config, pkgs, lib, ... }: {
    home.stateVersion = "25.11";
    programs = {
      starship = {
        enable = true;
        settings = lib.importTOML (pkgs.fetchurl {
          url = "https://starship.rs/presets/toml/gruvbox-rainbow.toml";
          sha256 = "sha256-P5+A3bi301zYRrm6EXzFfpSVdCWCOFttzxyF+pI2Th8="; 
        });
      };

      git = {
        enable = true;
        settings = {
          user = {
            name = "Guillermo Themsel";
            email = "themselg@icloud.com";
          };
        };
      };

      distrobox = {
        enable = true;
        containers = {
          python3 = {
            entry = false;
            image = "docker.io/python:3.12";
            additional_packages = "git";
          };
        };
      };

    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Escritorio";
      documents = "${config.home.homeDirectory}/Documentos";
      download = "${config.home.homeDirectory}/Descargas";
      music = "${config.home.homeDirectory}/Música";
      pictures = "${config.home.homeDirectory}/Imágenes";
      videos = "${config.home.homeDirectory}/Videos";
      publicShare = "${config.home.homeDirectory}/Público";
      templates = "${config.home.homeDirectory}/Plantillas";
    };

    dconf.settings = {
      "org/gnome/Console" = {
        "custom-font" = "AdwaitaMono Nerd Font 11";
        "use-system-font" = false;
      };

      "org/gnome/shell/extensions/app-hider" = {
        "hidden-apps" = [ "cups.desktop" "nixos-manual.desktop" "io.github.Foldex.AdwSteamGtk.desktop" "org.gnome.Tour.desktop" ];
        "hidden-search-apps" = [ "cups.desktop" "org.gnome.Tour.desktop" ];
      };

      "org/gnome/desktop/interface" = {
        "gtk-theme" = "adw-gtk3";
      };

      "org/gnome/shell" = {
          "disable-user-extensions" = "false";
          "enabled-extensions" = [ 
            "user-theme@gnome-shell-extensions.gcampax.github.com" 
            "rounded-window-corners@fxgn" 
            "caffeine@patapon.info" 
            "appindicatorsupport@rgcjonas.gmail.com" 
            "app-hider@lynith.dev" 
          ] ++ lib.optionals isLaptop [ 
            "touchup@mityax"
          ];
          "disabled-extensions" = [];
      };

      "org/gnome/shell/extensions/user-theme" = {
        "name" = "rewaita";
      };

      "org/gnome/desktop/input-sources" = {
        sources = [ (lib.gvariant.mkTuple [ "xkb" "us+intl" ]) ];
      };
    };

    home.activation.configureRoundedCorners = lib.hm.dag.entryAfter ["dconfSettings"] ''
      ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/rounded-window-corners-reborn/global-rounded-corner-settings \
      "{
        'padding': <{'left': uint32 1, 'right': uint32 1, 'top': uint32 1, 'bottom': uint32 1}>, 
        'keepRoundedCorners': <{'maximized': false, 'fullscreen': false}>, 
        'borderRadius': <uint32 16>, 
        'smoothing': <0.0>, 
        'borderColor': <(0.5, 0.5, 0.5, 1.0)>, 
        'enabled': <true>
      }"
    '';

    home.file.".dotfiles/zen-user.js".source = pkgs.fetchurl {
       url = "https://raw.githubusercontent.com/themselg/nix-dotfiles/main/user.js";
       sha256 = "sha256-HfIn+tDYhLsWl+MYJXsBhKNmJCWoOcB8KK/DUa/FBb0="; 
    };

    home.activation.injectZenConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ZEN_PATH="${config.home.homeDirectory}/.var/app/app.zen_browser.zen/.zen"
      if [ -d "$ZEN_PATH" ]; then
        PROFILE_DIR=$(find "$ZEN_PATH" -maxdepth 1 -type d -name "*.Default (release)" | head -n 1)
        
        if [ -n "$PROFILE_DIR" ]; then
          cat "${config.home.homeDirectory}/.dotfiles/zen-user.js" > "$PROFILE_DIR/user.js"
        else
          echo "No zen profile found"
        fi
      fi
    '';

  };  

}
