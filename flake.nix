{
  description = "My NVF configuration :)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs = {
    self,
    nixpkgs,
    nvf,
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Main nvf configuration as a function that takes pkgs
    nvfConfiguration = {pkgs}:
      nvf.lib.neovimConfiguration {
        modules = [./config/default.nix];
        inherit pkgs;
      };

    # Pre-built packages for each system
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = self.nvfConfiguration {inherit pkgs;};
      nvf = self.nvfConfiguration {inherit pkgs;};
    });

    # Apps to run directly
    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/nvim";
      };
    });

    # Overlay to add your nvf config to any pkgs
    overlays.default = final: prev: {
      my-nvf = self.nvfConfiguration {pkgs = final;};
    };

    # Home Manager module (optional)
    homeManagerModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.programs.my-nvf = {
        enable = lib.mkEnableOption "My nvf configuration";
      };

      config = lib.mkIf config.programs.my-nvf.enable {
        home.packages = [(self.nvfConfiguration {inherit pkgs;})];
      };
    };
  };
}
