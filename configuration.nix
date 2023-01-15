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
    address = "172.16.1.2";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "172.16.1.1";
  networking.nameservers = [ "172.16.1.1" ];

  networking.hostName = "mailnix";

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
      paths = [ "/home/johan" "/home/gunnel" ];
      doInit = true;
      repo =  "borg@borgnix.rylander.cc:/borg/repos/mailnix" ;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /root/borgbackup_passphrase";
      };
      environment = { BORG_RSH = "ssh -i /root/.ssh/id_ed25519_mailnix"; };
      compression = "auto,lzma";
      startAt = "hourly";
      preHook = "${pkgs.curl}/bin/curl https://hc-ping.com/194fff2e-6b99-4401-9c94-722ec9d9291a/start";
      postHook = "${pkgs.curl}/bin/curl https://hc-ping.com/194fff2e-6b99-4401-9c94-722ec9d9291a/$exitStatus";
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
      "43 * * * * gunnel curl https://hc-ping.com/3372cc35-c8b6-4f15-8ce5-696c6f21a745/start && offlineimap ; curl https://hc-ping.com/3372cc35-c8b6-4f15-8ce5-696c6f21a745/$?"
      "43 * * * * gunnel curl https://hc-ping.com/76e647e5-a106-4244-b398-9677bb4929a2/start && vdirsyncer sync ; curl https://hc-ping.com/76e647e5-a106-4244-b398-9677bb4929a2/$?"
      "13 * * * * gunnel curl https://hc-ping.com/fbb3aec9-ea25-4a3f-b454-91fa9520285d/start && curl -s 'http://calendar.zoho.com/ical/170fdaa44aa7cab3f2516a7b54be0fa74780743c57010d8f71995ec65ee3518f27c2209abcb83c218bd265e49977d416/pvt_c429ec61f3d14d7e9e590707439416d9' > $HOME/calendar.ics ; curl https://hc-ping.com/fbb3aec9-ea25-4a3f-b454-91fa9520285d/$?"

      "13 * * * * johan curl https://hc-ping.com/1bcf3886-1234-4528-b761-f39e353f4b52/start && offlineimap ; curl https://hc-ping.com/1bcf3886-1234-4528-b761-f39e353f4b52/$?"
      "13 * * * * johan curl https://hc-ping.com/ab8eefe7-e056-474e-abf5-80544bff7b6a/start && vdirsyncer sync ; curl https://hc-ping.com/ab8eefe7-e056-474e-abf5-80544bff7b6a/$?"
      "13 * * * * johan curl https://hc-ping.com/457f83b2-0d99-4948-a72f-b7e361727f74/start && curl -s 'http://calendar.zoho.com/ical/28a272d944661c2c69d70025bade08ff79de55e8bca645d45af24580b9f95ad44205fd6a2c62c993ca56d80b468cdf5f/pvt_abaf348720c6415395a058f814b76390' > $HOME/calendar.ics ; curl https://hc-ping.com/457f83b2-0d99-4948-a72f-b7e361727f74/$?"
    ];
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
    helix
    offlineimap
    vdirsyncer
  ];

  environment.shells = with pkgs; [ zsh ];

  programs.zsh.enable = true;

  services.openssh = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions 
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

