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
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "nextcloud";

  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "10.0.2.10";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "10.0.2.1";
  networking.nameservers = [ "1.1.1.1" ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 ];
  };

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

  users.users.jrylander = {
    isNormalUser = true;
    description = "Johan Rylander";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCL8m1YzDxHJ0Xpw68YO+j2qppbSBGcYHsufQAnVPWmqIa2Na00PHTsLacNAJn4wx3/TS+7rjtGywF0Wmkk6z0Ylzvt1ZHSZ7VPFa9VCzJdvx/6hHhwbvOus9C6iYmpzubmRJmRtp45QXgAFmIiJ2vR7nIfEgKi2RPrT0Kl3MuDKvgKxWswxF+wpz5HI6TmqB/TmLtewibEvq3QM8hPMf/oC+D12hg1KO5k1hEUOAolwUMWM4hiqN/KGACykcbHT4pmMFnoEiUvcS5888sMqhfrLaJ7M0sI+xiBRVU0KbjyeEsJsSvIm8Jcs/oXWMTdppjZXAm0prE+1EvDH7CTtWbGvlUDqpFxLsEUsamMz/p71kzQi8oI21I1jk9f/lYvrUR4raMo12Rjee3DcSa4GwcQUgru1jqE04/6DUrIXJlX0M2e6kO1bz7NKnxoWJOTpWOoRebR11MvOfejKNN4ImlTuvY4p/oWSNnZFdmtKwmi0f8hZvdnbNYxr7HUbfDiXtk= jrylander@server"
    ];
    shell = pkgs.zsh;
  };
  
  environment.shells = with pkgs; [ zsh ];

  environment.systemPackages = with pkgs; [
    git
    neovim
    tmux
  ];
  
  environment.variables = { EDITOR = "${pkgs.neovim}/bin/nvim"; };

  services.openssh.enable = true;
  
  services.qemuGuest.enable = true;

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud25;
    hostName = "nextcloud.rylander.cc";
    extraApps = with pkgs.nextcloud25Packages.apps; {
      inherit contacts calendar;
    };
    extraAppsEnable = true;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "10.0.2.4";
      dbport = 5432;
      dbname = "nextcloud";
      dbpassFile = "/etc/nextcloud/pg-pass-file";
      adminpassFile = "/etc/nextcloud/admin-pass-file";
      adminuser = "root";
      defaultPhoneRegion = "SE";
      overwriteProtocol = "https";
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
