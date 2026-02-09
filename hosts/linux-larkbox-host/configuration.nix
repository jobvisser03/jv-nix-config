{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common/nixos
    ../../modules/system
    ../../profiles
    ../../modules/sops
    ./secrets.nix
    ../../modules/homelab
  ];

  networking.hostName = "larkbox";
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  users.users.job = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"];
    shell = pkgs.zsh;
  };

  services.openssh.enable = true;

  # GitLab configuration
  services.gitlab = {
    enable = true;
    databasePasswordFile = config.sops.secrets.gitlab_database_password.path;
    initialRootPasswordFile = config.sops.secrets.gitlab_initial_root_password.path;
    secrets = {
      secretFile = config.sops.secrets.gitlab_secret.path;
      otpFile = config.sops.secrets.gitlab_otp_secret.path;
      dbFile = config.sops.secrets.gitlab_db_secret.path;
      jwsFile = config.sops.secrets.gitlab_jws_key.path;
    };
  };

  # Nginx reverse proxy for GitLab
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      localhost = {
        locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
      };
    };
  };

  programs.vscodeRemoteSSH.enable = true;
  programs.hyprland.enable = true;

  services.greetd.settings.initial_session = {
    command = "${pkgs.hyprland}/bin/start-hyprland";
    user = "job";
  };

  powerManagement.desktopMode = true;
  hardware.graphics.enable = true;

  homelab = {
    enable = true;
    services.enable = true;
    services.enableReverseProxy = false;

    services.immich = {
      enable = true;
      externalLibraryDirs = [
        "/mnt/usb-drive/PHOTOS-PCLOUD"
        "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD"
      ];
    };

    services.homepage.enable = true;

    services.radicale = {
      enable = false;
      passwordFile = config.sops.secrets.radicale_htpasswd.path;
    };

    services.homeassistant = {
      enable = true;
      zigbee2mqtt = {
        enable = true;
        usbDevice = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_34bde4cea845ed1184b8d18f0a86e0b4-if00-port0";
      };
      mosquitto.enable = true;
    };

    services.rclone = {
      enable = true;
      configFile = config.sops.secrets.rclone_config.path;
      mounts = {
        pcloud-photos = {
          remote = "pcloud:PHOTOS";
          mountpoint = "/mnt/usb-drive/PHOTOS-PCLOUD";
          cacheMode = "minimal";
          readOnly = true;
          requiredMounts = ["/mnt/usb-drive"];
        };
        pcloud-smartphone-photos = {
          remote = "pcloud:'Automatic Upload'";
          mountpoint = "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD";
          cacheMode = "minimal";
          readOnly = true;
          requiredMounts = ["/mnt/usb-drive"];
        };
        pcloud-keepass = {
          remote = "pcloud:keepass-vault";
          mountpoint = "/home/job/pcloud/keepass-vault";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    apacheHttpd
  ];

  system.stateVersion = "25.11";
}
