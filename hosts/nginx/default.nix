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

  environment.etc."nc-adminpass".text = "root"; #disable root account after initial setup
  environment.systemPackages = with pkgs; [
    git
    gh
    vim
  ];

  boot.isContainer = true;
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 204800;
  };

  networking = {
    hostName = "nginx";
  };

  zramSwap.enable = true;
  boot.tmp.cleanOnBoot = true;

  networking.firewall = {
    allowedTCPPorts = [ 22000 8384 80 443 32400 ];
    allowedUDPPorts = [ 21027 22000 ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "kosslan@proton.me";
  };

  services = {
    openssh = {
      enable = true;
    };

    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "nextcloud.kosslan.dev" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://192.168.10.102";
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 512M;
              client_body_timeout 300s;
              fastcgi_buffers 64 4K;
              client_body_buffer_size 512k;
              proxy_ssl_server_name on;
              proxy_pass_header Authorization;
            '';
          };
        };
      };
    };
  };

  system.activationScripts.installInitScript = lib.mkForce ''
    mkdir -p /sbin
    ln -fs $systemConfig/init /sbin/init
  '';

  users.users.root.initialPassword = "root";
  users.users.root.openssh.authorizedKeys.keys = [ ''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpkeLOreGeqUDLcrlYgzyeSSZmBvJLY+dWOeORIpGQQVRvlko8NRcVKS/fa5EHBd9HG9gRs96FK5WF9JJCGsY4ovL++WZwlsQN3xfc0xq2Sn8TQhgDgiBFCR05JDMi1+f6v9WpaiLiQnOKiTmSGYhzvayIr/XrpcAaXo0mLDEnqZbSzqTcAcqZMcPZixmkgFJA+kUq6d1Z5XMPRRTPJNmLGY0jNbVlUiI9pWsIlGqZFcMLssNWnIZkl8SCV/lN+uyFy2G1o1LlMQ6UFziqP3Zm28gq6alt7ivFJ8A8hUffiZWeQ4uURV8TKhQ43FGSUspma7DpG5zGdionkN521rQJajdnWJLO25dXRkDdXWmkwpFuKRep0m0xv0VSxXAPYs5IrFuDuylbfo6W0N5dx2sPgBK8cQ2uj5AvVCM6g8cgWh+pxzG/WV/2XpwrT7jD8vyRUL+U6FpiMQIsepJ/WQIhA7HkQnex2QHGAsu7hP5Wr5Bs33m8JYT5XCT0KsXkzQE= koss@galahad'' ];

  system.stateVersion = "23.11";
}
