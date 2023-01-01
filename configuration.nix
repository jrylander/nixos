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
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "172.16.1.7";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "172.16.1.1";
  networking.nameservers = [ "172.16.1.1" ];

  networking.hostName = "borgnix";

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

  services.borgbackup.repos = {
    nuc = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPUuhDB9ZFFJhX+8ZvcXCVBG6HuJv6IW2SwTwcjfEGwj root@pve-r430"
      ] ;
      path = "/borg/repos/nuc" ;
    };
    mailbackup = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFKxCuVeFCQvz18yRJQcF0gB/5LXy8WiF9bfSC/C8Ty root@pve-r430"
      ] ;
      path = "/borg/repos/mailbackup" ;
    };
    syncnix = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA78ecQaIJt6LjahNxLa7/yzOOwh78mBZ7U2qno59O11 root@pve-r430"
      ] ;
      path = "/borg/repos/syncnix" ;
    };
  };


  users.users.jrylander = {
    isNormalUser = true;
    description = "Johan Rylander";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIIa7FHeL2hL+fqE04qhW0AscTxhaZXhAuy9nt3h1gXsNAAAABHNzaDo="
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHalfm4hMsq8J3aLzgNxVIjZDQV/VAJEE8Tfgj2Pd7UwAAAABHNzaDo="
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBgwP5XNAWbG9HRlLBk0s7bcyIqhjh2fGWmeU5U5Gqw3AAAABHNzaDo="
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBfyTh9qEOUOTjf+EeZ0U6AlbtBRMimeh0Y0wphM2IBhAAAABHNzaDo="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCL8m1YzDxHJ0Xpw68YO+j2qppbSBGcYHsufQAnVPWmqIa2Na00PHTsLacNAJn4wx3/TS+7rjtGywF0Wmkk6z0Ylzvt1ZHSZ7VPFa9VCzJdvx/6hHhwbvOus9C6iYmpzubmRJmRtp45QXgAFmIiJ2vR7nIfEgKi2RPrT0Kl3MuDKvgKxWswxF+wpz5HI6TmqB/TmLtewibEvq3QM8hPMf/oC+D12hg1KO5k1hEUOAolwUMWM4hiqN/KGACykcbHT4pmMFnoEiUvcS5888sMqhfrLaJ7M0sI+xiBRVU0KbjyeEsJsSvIm8Jcs/oXWMTdppjZXAm0prE+1EvDH7CTtWbGvlUDqpFxLsEUsamMz/p71kzQi8oI21I1jk9f/lYvrUR4raMo12Rjee3DcSa4GwcQUgru1jqE04/6DUrIXJlX0M2e6kO1bz7NKnxoWJOTpWOoRebR11MvOfejKNN4ImlTuvY4p/oWSNnZFdmtKwmi0f8hZvdnbNYxr7HUbfDiXtk= jrylander@server"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    rclone
  ];

  environment.shells = with pkgs; [ zsh ];

  programs.zsh.enable = true;

  services.openssh = {
    enable = true;
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "30 1-23 * * * root curl https://hc-ping.com/f1ee43d6-2438-455a-8b0f-4a115f07249c/start && rclone sync --b2-hard-delete /borg/repos b2:rylander-backups ; curl https://hc-ping.com/f1ee43d6-2438-455a-8b0f-4a115f07249c/$?"
    ];
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

