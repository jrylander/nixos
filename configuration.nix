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

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "172.16.1.8";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "172.16.1.1";
  networking.nameservers = [ "172.16.1.1" ];

  networking.hostName = "zwave";

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

  services.borgbackup.jobs = {
    borgnix = {
      paths = [ "/dockerdata" ];
      doInit = true;
      repo =  "borg@borgnix.rylander.cc:/borg/repos/zwave" ;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /root/borgbackup_passphrase";
      };
      environment = { BORG_RSH = "ssh -i /root/.ssh/id_ed25519_zwave"; };
      compression = "auto,lzma";
      startAt = "hourly";
      preHook = "${pkgs.curl}/bin/curl https://hc-ping.com/b64eb35d-f922-4f9d-9f40-6c79748dab02/start";
      postHook = "${pkgs.curl}/bin/curl https://hc-ping.com/b64eb35d-f922-4f9d-9f40-6c79748dab02/$exitStatus";
    };
  };

  users.users.jrylander = {
    isNormalUser = true;
    description = "Johan Rylander";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIIa7FHeL2hL+fqE04qhW0AscTxhaZXhAuy9nt3h1gXsNAAAABHNzaDo="
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHalfm4hMsq8J3aLzgNxVIjZDQV/VAJEE8Tfgj2Pd7UwAAAABHNzaDo="
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBgwP5XNAWbG9HRlLBk0s7bcyIqhjh2fGWmeU5U5Gqw3AAAABHNzaDo="
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBfyTh9qEOUOTjf+EeZ0U6AlbtBRMimeh0Y0wphM2IBhAAAABHNzaDo="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCL8m1YzDxHJ0Xpw68YO+j2qppbSBGcYHsufQAnVPWmqIa2Na00PHTsLacNAJn4wx3/TS+7rjtGywF0Wmkk6z0Ylzvt1ZHSZ7VPFa9VCzJdvx/6hHhwbvOus9C6iYmpzubmRJmRtp45QXgAFmIiJ2vR7nIfEgKi2RPrT0Kl3MuDKvgKxWswxF+wpz5HI6TmqB/TmLtewibEvq3QM8hPMf/oC+D12hg1KO5k1hEUOAolwUMWM4hiqN/KGACykcbHT4pmMFnoEiUvcS5888sMqhfrLaJ7M0sI+xiBRVU0KbjyeEsJsSvIm8Jcs/oXWMTdppjZXAm0prE+1EvDH7CTtWbGvlUDqpFxLsEUsamMz/p71kzQi8oI21I1jk9f/lYvrUR4raMo12Rjee3DcSa4GwcQUgru1jqE04/6DUrIXJlX0M2e6kO1bz7NKnxoWJOTpWOoRebR11MvOfejKNN4ImlTuvY4p/oWSNnZFdmtKwmi0f8hZvdnbNYxr7HUbfDiXtk= jrylander@server"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    helix
    usbutils
  ];

  environment.shells = with pkgs; [ zsh ];

  programs.zsh.enable = true;

  services.openssh = {
    enable = true;
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
        image = "ghcr.io/home-assistant/home-assistant:2023.1.0";
        extraOptions = [ 
          "--network=host" 
        ];
      };
      containers.zwavejs2mqtt = {
        volumes = [ "/dockerdata/zwavejs2mqtt:/usr/src/app/store" ];
        environment.TZ = "Europe/Stockholm";
        image = "zwavejs/zwave-js-ui:8.6.3";
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
