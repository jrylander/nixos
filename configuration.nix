# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "borg-dmz";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "10.0.2.8";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "10.0.2.1";
  networking.nameservers = [ "1.1.1.1" ];

  time.timeZone = "Europe/Stockholm";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  services.qemuGuest.enable = true;

  services.netdata = {
    enable = true;

    config = {
      global = {
        # uncomment to reduce memory to 32 MB
        #"page cache size" = 32;

        # update interval
        "update every" = 15;
      };
      ml = {
        # enable machine learning
        "enabled" = "yes";
      };
    };
  };

  services.borgbackup.repos = {
    syncnix = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA78ecQaIJt6LjahNxLa7/yzOOwh78mBZ7U2qno59O11 root@pve-r430"
      ] ;
      path = "/borg/repos/syncnix" ;
    };
    postgrez = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMBScyuOLzEesoAxcK+uo6gjvUEDwuj94+zLKAJ0ypKe Postgrez borg backup"
      ] ;
      path = "/borg/repos/postgrez" ;
    };
    nextcloud = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYVH3lnQcJ7ljG4Jog6hUFD2wWdvCD7EnUlMipmdGce Nextcloud borg backup"
      ] ;
      path = "/borg/repos/nextcloud" ;
    };
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "30 0-23/4 * * * root curl https://hc-ping.com/def007db-9547-4402-bf1e-08769d102944/start && rclone sync --b2-hard-delete /borg/repos b2:rylander-backups-dmz ; curl https://hc-ping.com/def007db-9547-4402-bf1e-08769d102944/$?"
    ];
  };
  
  systemd.timers."borg-compact" = {
  wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Unit = "borg-compact.service";
    };
};

  systemd.services."borg-compact" = {
    script = ''
      for i in $(ls -d /borg/repos/*) ; do /run/current-system/sw/bin/borg compact $i ; done
      '';
    serviceConfig = {
      Type = "oneshot";
      User = "borg";
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "jrylander" ];
      commands = [
        {
          command = "ALL";
          options = [ "SETENV" "NOPASSWD" ];
        }
      ];
    }
  ];

  users.users.jrylander = {
    isNormalUser = true;
    description = "Johan Rylander";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCL8m1YzDxHJ0Xpw68YO+j2qppbSBGcYHsufQAnVPWmqIa2Na00PHTsLacNAJn4wx3/TS+7rjtGywF0Wmkk6z0Ylzvt1ZHSZ7VPFa9VCzJdvx/6hHhwbvOus9C6iYmpzubmRJmRtp45QXgAFmIiJ2vR7nIfEgKi2RPrT0Kl3MuDKvgKxWswxF+wpz5HI6TmqB/TmLtewibEvq3QM8hPMf/oC+D12hg1KO5k1hEUOAolwUMWM4hiqN/KGACykcbHT4pmMFnoEiUvcS5888sMqhfrLaJ7M0sI+xiBRVU0KbjyeEsJsSvIm8Jcs/oXWMTdppjZXAm0prE+1EvDH7CTtWbGvlUDqpFxLsEUsamMz/p71kzQi8oI21I1jk9f/lYvrUR4raMo12Rjee3DcSa4GwcQUgru1jqE04/6DUrIXJlX0M2e6kO1bz7NKnxoWJOTpWOoRebR11MvOfejKNN4ImlTuvY4p/oWSNnZFdmtKwmi0f8hZvdnbNYxr7HUbfDiXtk= jrylander@server"
    ];
    shell = pkgs.zsh;
  };

  environment.shells = with pkgs; [ zsh ];

  environment.systemPackages = with pkgs; [
    neovim
    git
    rclone
  ];

  environment.variables = { EDITOR = "${pkgs.neovim}/bin/nvim"; };

  services.openssh.enable = true;

  services.fail2ban.enable = true;


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
