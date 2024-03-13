{ config
, lib
, pkgs
, outputs
, inputs
, ...
}: {
  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  environment.etc."nc-adminpass".text = "Root12345!";
  environment.systemPackages = with pkgs; [
    git
    gh
    vim
  ];

  boot.isContainer = true;

  networking = {
    hostName = "nextcloud";
  };

  networking.firewall = {
    allowedTCPPorts = [ 22000 8384 80 443 ];
    allowedUDPPorts = [ 21027 22000 ];
  };

  services = {
    openssh = {
      enable = true;
    };

    # IMPORTANT: MUST BE ENABLED OTHERWISE THIS DOES NOT WORK THANKS!!!!! WOW
    nginx.enable = true;

    nextcloud = {
      enable = true;
      package = pkgs.nextcloud28;
      hostName = "nextcloud.kosslan.dev";
      appstoreEnable = true;

      configureRedis = true;
      notify_push.enable = false;
      maxUploadSize = "51200M";
      https = true;

      phpExtraExtensions = all: [ all.smbclient all.inotify ];

      phpOptions = {
        "opcache.interned_strings_buffer" = 24;
      };

      settings = {
        trusted_domains = [ "192.168.10.115" ];
        trusted_proxies = [ "192.168.10.115" "192.168.10.102" ];
        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
        ];

        "filelocking.enabled" = true;
      };

      database.createLocally = true;

      config = {
        adminpassFile = "/etc/nc-adminpass";
        dbtype = "mysql";
      };

      caching = {
        redis = true;
        memcached = true;
      };
    };

    syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
    };
  };

  system.activationScripts.installInitScript = lib.mkForce ''
    mkdir -p /sbin
    ln -fs $systemConfig/init /sbin/init
  '';

  users.users.nextcloud = {
    extraGroups = [ "syncthing" ];
  };

  users.users.root.initialPassword = "root";
  users.users.root.openssh.authorizedKeys.keys = [ ''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpkeLOreGeqUDLcrlYgzyeSSZmBvJLY+dWOeORIpGQQVRvlko8NRcVKS/fa5EHBd9HG9gRs96FK5WF9JJCGsY4ovL++WZwlsQN3xfc0xq2Sn8TQhgDgiBFCR05JDMi1+f6v9WpaiLiQnOKiTmSGYhzvayIr/XrpcAaXo0mLDEnqZbSzqTcAcqZMcPZixmkgFJA+kUq6d1Z5XMPRRTPJNmLGY0jNbVlUiI9pWsIlGqZFcMLssNWnIZkl8SCV/lN+uyFy2G1o1LlMQ6UFziqP3Zm28gq6alt7ivFJ8A8hUffiZWeQ4uURV8TKhQ43FGSUspma7DpG5zGdionkN521rQJajdnWJLO25dXRkDdXWmkwpFuKRep0m0xv0VSxXAPYs5IrFuDuylbfo6W0N5dx2sPgBK8cQ2uj5AvVCM6g8cgWh+pxzG/WV/2XpwrT7jD8vyRUL+U6FpiMQIsepJ/WQIhA7HkQnex2QHGAsu7hP5Wr5Bs33m8JYT5XCT0KsXkzQE= koss@galahad'' ];

  system.stateVersion = "24.05";
}
