{ inputs
, outputs
, stateVersion
, ...
}: {
  # Helper function for generating host configs
  mkHost =
    { hostname
    , desktop ? null
    , pkgsInput ? inputs.nixpkgs
    ,
    }:
    pkgsInput.lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs stateVersion hostname desktop;
      };
      modules = [ ../../hosts/${hostname} ];
    };

  mkLxcImage = { hostname }:
    inputs.nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      modules = [
        ../../hosts/${hostname}
      ];
      format = "proxmox-lxc";

      # pkgs = nixpkgs.legacyPackages.x86_64-linux;
      # lib = nixpkgs.legacyPackages.x86_64-linux.lib;
      specialArgs = { inherit outputs inputs; };
    };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
