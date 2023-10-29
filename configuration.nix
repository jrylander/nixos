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

  networking.hostName = "mailnix";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "172.16.1.2";
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

  services.borgbackup.jobs = {
    borgnix = {
      paths = [ "/home/johan" "/home/gunnel" ];
      doInit = true;
      repo =  "borg@borg.rylander.cc:/borg/repos/mailnix" ;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /root/borgbackup_passphrase";
      };
      environment = { BORG_RSH = "ssh -i /root/.ssh/id_ed25519_mailnix"; };
      compression = "auto,lzma";
      startAt = [];
      preHook = "${pkgs.curl}/bin/curl https://hc-ping.com/194fff2e-6b99-4401-9c94-722ec9d9291a/start && /run/current-system/sw/bin/systemctl stop cron";
      postHook = "/run/current-system/sw/bin/systemctl start cron && if [ $exitStatus -eq 1 ] ; then ${pkgs.curl}/bin/curl https://hc-ping.com/194fff2e-6b99-4401-9c94-722ec9d9291a/0 ; else ${pkgs.curl}/bin/curl https://hc-ping.com/194fff2e-6b99-4401-9c94-722ec9d9291a/$exitStatus ; fi";
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

  users.users.johan = {
    isNormalUser = true;
    description = "Johan Rylander";
  };

  users.users.gunnel = {
    isNormalUser = true;
    description = "Gunnel Rylander";
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "30 17-22 * * * root systemctl is-active borgbackup-job-borgnix.service || systemctl start borgbackup-job-borgnix.service"

      "43 17-22 * * * gunnel curl https://hc-ping.com/3372cc35-c8b6-4f15-8ce5-696c6f21a745/start && offlineimap ; curl https://hc-ping.com/3372cc35-c8b6-4f15-8ce5-696c6f21a745/$?"
      "41 17-22 * * * gunnel curl https://hc-ping.com/76e647e5-a106-4244-b398-9677bb4929a2/start && vdirsyncer sync ; curl https://hc-ping.com/76e647e5-a106-4244-b398-9677bb4929a2/$?"
      "37 17-22 * * * gunnel curl https://hc-ping.com/fbb3aec9-ea25-4a3f-b454-91fa9520285d/start && curl -s 'http://calendar.zoho.com/ical/170fdaa44aa7cab3f2516a7b54be0fa74780743c57010d8f71995ec65ee3518f27c2209abcb83c218bd265e49977d416/pvt_c429ec61f3d14d7e9e590707439416d9' > $HOME/calendar.ics ; curl https://hc-ping.com/fbb3aec9-ea25-4a3f-b454-91fa9520285d/$?"

      "13 17-22 * * * johan curl https://hc-ping.com/1bcf3886-1234-4528-b761-f39e353f4b52/start && offlineimap ; curl https://hc-ping.com/1bcf3886-1234-4528-b761-f39e353f4b52/$?"
      "17 17-22 * * * johan curl https://hc-ping.com/4c02ab13-d67b-48b8-a8fe-c136b9c4d6be/start && vdirsyncer sync ; curl https://hc-ping.com/4c02ab13-d67b-48b8-a8fe-c136b9c4d6be/$?"
      "15 17-22 * * * johan curl https://hc-ping.com/599ae22e-894a-4558-bcd4-8184d23fbc14/start && curl -s 'http://calendar.zoho.eu/ical/zz08011230162f3b2e6458e4eb7a3348c424f25fdc889bf0563e6e1856f6407db0f36cf0bff234e495461a5d60e313e223f9a37562/pvt_d1f2216da1b64b6a9a99c20285661397' > $HOME/calendar.ics ; curl https://hc-ping.com/599ae22e-894a-4558-bcd4-8184d23fbc14/$?"
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
    offlineimap
    vdirsyncer
  ];

  environment.variables = { EDITOR = "nvim"; };

  services.openssh.enable = true;


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
