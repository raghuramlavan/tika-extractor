{
  description = "(insert short project description here)";

  inputs.nixpkgs.url = "nixpkgs/nixos-20.09";
  inputs.mvn2nix.url = "github:fzakaria/mvn2nix";

  outputs = { self, nixpkgs, mvn2nix }:
    let

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

      pkgsForSystem = forAllSystems( system: import nixpkgs {
        # ./overlay.nix contains the logic to package local repository
        overlays = [ mvn2nix.overlay (
            final: prev: {
            tikaExtractor = final.callPackage ./tikaExtractor.nix { };
            }
        ) ];
        inherit system;
      });
 
    in

    {


      packages = forAllSystems (system:
        {
          inherit (pkgsForSystem.${system}) tikaExtractor;
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.tikaExtractor);

      nixosModules.tika-extractor={config, nixpkgs, lib,...}:with lib; {

                options = {

                  services.tika-extractor = {
                    enable = mkOption {
                      type = types.bool;
                      default = false;
                      description = ''
                      tika extractor
                      '';
                    };
                  };

                };


                ###### implementation

                config = mkIf config.services.tika-extractor.enable {
                  systemd.services.tika-extractor = {
                    description = "Tika extractor";
                    serviceConfig = {
                      ExecStart =  "${self.packages.x86_64-linux.tika-extractor-1.1}/bin/tika-extractor";
                      
                    };
                  };
                };
         
         };

    };
}
