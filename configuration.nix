# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, modulesPath, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (modulesPath + "/profiles/headless.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "syncnix";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.dhcpcd.enable = false;

  networking.interfaces.ens19.ipv4.addresses = [ {
    address = "10.0.2.3";
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

  networking.firewall.allowedTCPPorts = [ 8384 22000];
  networking.firewall.allowedUDPPorts = [ 22000 21027];

  services = {
    syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
      user = "syncthing";
      dataDir = "/syncthing";
      configDir = "/syncthing/config";
    };
  };

  users.users.syncthing = {
    home = "/syncthing";
  };

  services.borgbackup.jobs = {
    borgnix = {
      paths = [ "/syncthing" ];
      doInit = true;
      repo =  "borg@10.0.2.8:/borg/repos/syncnix" ;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /root/borgbackup_passphrase";
      };
      environment = { BORG_RSH = "ssh -i /root/.ssh/id_ed25519_syncnix"; };
      compression = "auto,lzma";
      startAt = [];
      preHook = "${pkgs.curl}/bin/curl https://hc-ping.com/294d2224-bb2a-447b-b62e-3ab2c27183c4/start && /run/current-system/sw/bin/systemctl stop syncthing && sleep 10";
      postHook = "/run/current-system/sw/bin/systemctl start syncthing && if [ $exitStatus -eq 1 ] ; then ${pkgs.curl}/bin/curl https://hc-ping.com/294d2224-bb2a-447b-b62e-3ab2c27183c4/0 ; else ${pkgs.curl}/bin/curl https://hc-ping.com/294d2224-bb2a-447b-b62e-3ab2c27183c4/$exitStatus ; fi";
      prune = {
        keep = {
          daily = 7;
          weekly = 4;
          monthly = 6;
          yearly = 5;
        };
      };
    };
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "20 17-22 * * * root systemctl is-active borgbackup-job-borgnix.service || systemctl start borgbackup-job-borgnix.service "
    ];
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
