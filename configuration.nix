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
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nuc";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  networking.interfaces.eno1.ipv4.addresses = [ {
    address = "172.16.1.5";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "172.16.1.1";
  networking.nameservers = [ "172.16.1.1" ];

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

  security.sudo.wheelNeedsPassword = false;

  users.users.jrylander = {
    isNormalUser = true;
    description = "Johan Rylander";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCL8m1YzDxHJ0Xpw68YO+j2qppbSBGcYHsufQAnVPWmqIa2Na00PHTsLacNAJn4wx3/TS+7rjtGywF0Wmkk6z0Ylzvt1ZHSZ7VPFa9VCzJdvx/6hHhwbvOus9C6iYmpzubmRJmRtp45QXgAFmIiJ2vR7nIfEgKi2RPrT0Kl3MuDKvgKxWswxF+wpz5HI6TmqB/TmLtewibEvq3QM8hPMf/oC+D12hg1KO5k1hEUOAolwUMWM4hiqN/KGACykcbHT4pmMFnoEiUvcS5888sMqhfrLaJ7M0sI+xiBRVU0KbjyeEsJsSvIm8Jcs/oXWMTdppjZXAm0prE+1EvDH7CTtWbGvlUDqpFxLsEUsamMz/p71kzQi8oI21I1jk9f/lYvrUR4raMo12Rjee3DcSa4GwcQUgru1jqE04/6DUrIXJlX0M2e6kO1bz7NKnxoWJOTpWOoRebR11MvOfejKNN4ImlTuvY4p/oWSNnZFdmtKwmi0f8hZvdnbNYxr7HUbfDiXtk= jrylander@server"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  environment.shells = with pkgs; [ zsh ];

  environment.systemPackages = with pkgs; [
    neovim
    git
    usbutils
  ];

  environment.variables = { EDITOR = "nvim"; };

  services.openssh.enable = true;

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

  services.borgbackup.jobs = {
    borgnix = {
      paths = [ "/dockerdata" ];
      doInit = true;
      repo =  "borg@borg.rylander.cc:/borg/repos/zwave" ;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /root/borgbackup_passphrase";
      };
     environment = { BORG_RSH = "ssh -i /root/.ssh/id_ed25519_zwave"; };
      compression = "auto,lzma";
      startAt = [];
      preHook = "${pkgs.curl}/bin/curl https://hc-ping.com/eada6e40-7a05-4d5b-a4c5-faa13f028968/start && /run/current-system/sw/bin/systemctl stop podman-homeassistant.service && sleep 10";
      postHook = "/run/current-system/sw/bin/systemctl start podman-homeassistant.service && if [ $exitStatus -eq 1 ] ; then ${pkgs.curl}/bin/curl https://hc-ping.com/eada6e40-7a05-4d5b-a4c5-faa13f028968/0 ; else ${pkgs.curl}/bin/curl https://hc-ping.com/eada6e40-7a05-4d5b-a4c5-faa13f028968/$exitStatus ; fi";
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
      "10 17-22 * * * root systemctl is-active borgbackup-job-borgnix.service || systemctl start borgbackup-job-borgnix.service "
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8123 8091 ];
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.dnsname.enable = true;
    };

    oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        volumes = [ "/dockerdata/home-assistant:/config" ];
        environment.TZ = "Europe/Stockholm";
        image = "ghcr.io/home-assistant/home-assistant:2023.10.3";
        extraOptions = [
          "--network=host"
        ];
      };
      containers.zwavejs2mqtt = {
        volumes = [ "/dockerdata/zwavejs2mqtt:/usr/src/app/store" ];
        environment.TZ = "Europe/Stockholm";
        image = "zwavejs/zwave-js-ui:9.1.2";
        extraOptions = [
          "--network=host"
          "--device=/dev/ttyACM0:/dev/ttyACM0"
        ];
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
