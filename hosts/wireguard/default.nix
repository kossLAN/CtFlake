{
  config,
  lib,
  pkgs,
  outputs,
  inputs,
  ...
}: {
  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    vim
  ];

  boot.isContainer = true;

  services = {
    openssh = {
      enable = true;
    };

    adguardhome = {
      enable = true;
      openFirewall = true;
      mutableSettings = true;
    };
  };

  networking = {
    hostName = "wireguard";
    firewall.allowedUDPPorts = [51820];
    firewall.allowedTCPPorts = [80 53];

    nat = {
      enable = true;
      externalInterface = "eth0";
      internalInterfaces = ["wg0"];
    };

    wireguard.interfaces = {
      wg0 = {
        ips = ["10.100.0.1/24"];
        listenPort = 51820;
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
          ${pkgs.iptables}/bin/iptables --table nat -A PREROUTING --in-interface wg0 --protocol udp --destination-port 53 --jump DNAT --to-destination 127.0.0.1
          ${pkgs.iptables}/bin/iptables --table nat -A PREROUTING --in-interface wg0 --protocol udp --destination-port 53 --jump DNAT --to-destination 192.168.10.104
        '';

        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
          ${pkgs.iptables}/bin/iptables --table nat -D PREROUTING --in-interface wg0 --protocol udp --destination-port 53 --jump DNAT --to-destination 127.0.0.1
          ${pkgs.iptables}/bin/iptables --table nat -D PREROUTING --in-interface wg0 --protocol udp --destination-port 53 --jump DNAT --to-destination 192.168.10.104
        '';

        privateKeyFile = "/etc/wg-private";
        peers = [
          # Phone
          {
            publicKey = "VZM6vpIOfaG2HyeQ1dnlvQqlv1Qx63C3uvS1kAlnwXQ=";
            allowedIPs = ["10.100.0.2/32"];
          }
          # Everything else
          {
            publicKey = "VZM6vpIOfaG2HyeQ1dnlvQqlv1Qx63C3uvS1kAlnwXQ=";
            allowedIPs = ["10.100.0.3/32"];
          }
        ];
      };
    };
  };

  system.activationScripts.installInitScript = lib.mkForce ''
    mkdir -p /sbin
    ln -fs $systemConfig/init /sbin/init
  '';

  users.users.root.initialPassword = "root";
  users.users.root.openssh.authorizedKeys.keys = [''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpkeLOreGeqUDLcrlYgzyeSSZmBvJLY+dWOeORIpGQQVRvlko8NRcVKS/fa5EHBd9HG9gRs96FK5WF9JJCGsY4ovL++WZwlsQN3xfc0xq2Sn8TQhgDgiBFCR05JDMi1+f6v9WpaiLiQnOKiTmSGYhzvayIr/XrpcAaXo0mLDEnqZbSzqTcAcqZMcPZixmkgFJA+kUq6d1Z5XMPRRTPJNmLGY0jNbVlUiI9pWsIlGqZFcMLssNWnIZkl8SCV/lN+uyFy2G1o1LlMQ6UFziqP3Zm28gq6alt7ivFJ8A8hUffiZWeQ4uURV8TKhQ43FGSUspma7DpG5zGdionkN521rQJajdnWJLO25dXRkDdXWmkwpFuKRep0m0xv0VSxXAPYs5IrFuDuylbfo6W0N5dx2sPgBK8cQ2uj5AvVCM6g8cgWh+pxzG/WV/2XpwrT7jD8vyRUL+U6FpiMQIsepJ/WQIhA7HkQnex2QHGAsu7hP5Wr5Bs33m8JYT5XCT0KsXkzQE= koss@galahad''];

  system.stateVersion = "23.11";
}
