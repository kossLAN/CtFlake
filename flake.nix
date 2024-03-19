{
  description = "Containers for on nixos configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    stateVersion = "23.11";
    libx = import ./lib {inherit inputs outputs stateVersion;};
  in {
    # NixOS Configurations
    nixosConfigurations = {
      cloud = libx.mkHost {
        hostname = "cloud";
        desktop = "";
      };
      nginx = libx.mkHost {
        hostname = "nginx";
        desktop = "";
      };
      plex = libx.mkHost {
        hostname = "plex";
        desktop = "";
      };
      wireguard = libx.mkHost {
        hostname = "wireguard";
        desktop = "";
      };
      adguard = libx.mkHost {
        hostname = "adguard";
        desktop = "";
      };
    };

    # LXC Images
    cloud = libx.mkLxcImage {
      hostname = "cloud";
    };

    plex = libx.mkLxcImage {
      hostname = "plex";
    };

    nginx = libx.mkLxcImage {
      hostname = "nginx";
    };
    wireguard = libx.mkLxcImage {
      hostname = "wireguard";
    };
    adguard = libx.mkLxcImage {
      hostname = "adguard";
    };
  };
}
