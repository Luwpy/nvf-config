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

    # Helper function to create nvf configuration
    makeNeovimConfig = {pkgs}: let
      nvfConfig = nvf.lib.neovimConfiguration {
        modules = [./config/default.nix];
        inherit pkgs;
      };
    in
      nvfConfig.neovim;
  in {
    # Pre-built packages for each system
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = makeNeovimConfig {inherit pkgs;};
      neovim = makeNeovimConfig {inherit pkgs;};
      nvf = makeNeovimConfig {inherit pkgs;};
    });

    # Apps to run directly
    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/nvim";
      };
      neovim = {
        type = "app";
        program = "${self.packages.${system}.neovim}/bin/nvim";
      };
    });

    # Overlay to add your nvf config to any pkgs
    overlays.default = final: prev: {
      my-neovim = makeNeovimConfig {pkgs = final;};
      my-nvf = makeNeovimConfig {pkgs = final;}; # Keep both names for compatibility
    };

    # NixOS module for system-wide installation
    nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.programs.my-neovim = {
        enable = lib.mkEnableOption "My custom Neovim configuration";

        package = lib.mkOption {
          type = lib.types.package;
          default = makeNeovimConfig {inherit pkgs;};
          description = "The Neovim package to use";
        };

        defaultEditor = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Set as default editor (EDITOR environment variable)";
        };

        aliases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["vim" "vi"];
          description = "Shell aliases to create for Neovim";
        };
      };

      config = lib.mkIf config.programs.my-neovim.enable {
        environment.systemPackages = [config.programs.my-neovim.package];

        environment.variables = lib.mkIf config.programs.my-neovim.defaultEditor {
          EDITOR = "${config.programs.my-neovim.package}/bin/nvim";
          VISUAL = "${config.programs.my-neovim.package}/bin/nvim";
        };

        programs.bash.shellAliases =
          lib.genAttrs
          config.programs.my-neovim.aliases
          (alias: "${config.programs.my-neovim.package}/bin/nvim");

        programs.zsh.shellAliases =
          lib.genAttrs
          config.programs.my-neovim.aliases
          (alias: "${config.programs.my-neovim.package}/bin/nvim");
      };
    };

    # Home Manager module
    homeManagerModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.programs.my-neovim = {
        enable = lib.mkEnableOption "My custom Neovim configuration";

        package = lib.mkOption {
          type = lib.types.package;
          default = makeNeovimConfig {inherit pkgs;};
          description = "The Neovim package to use";
        };

        defaultEditor = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Set as default editor";
        };

        aliases = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            vim = "nvim";
            vi = "nvim";
          };
          description = "Shell aliases to create";
        };

        sessionVariables = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
          description = "Extra session variables";
        };
      };

      config = lib.mkIf config.programs.my-neovim.enable {
        home.packages = [config.programs.my-neovim.package];

        home.sessionVariables =
          config.programs.my-neovim.sessionVariables
          // (
            lib.optionalAttrs config.programs.my-neovim.defaultEditor {
              EDITOR = "${config.programs.my-neovim.package}/bin/nvim";
              VISUAL = "${config.programs.my-neovim.package}/bin/nvim";
            }
          );

        programs.bash.shellAliases = config.programs.my-neovim.aliases;
        programs.zsh.shellAliases = config.programs.my-neovim.aliases;
        programs.fish.shellAliases = config.programs.my-neovim.aliases;
      };
    };

    # Development shell for testing
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "nvf-dev";

        buildInputs = with pkgs; [
          # Nix development tools
          nixd
          nil # Alternative to nixd
          alejandra
          nixfmt-rfc-style
          statix
          deadnix

          # Development utilities
          git
          fd
          ripgrep

          # LSP servers for testing
          lua-language-server
          rust-analyzer
          clang-tools
        ];

        shellHook = ''
          echo "🚀 NVF Development Environment"
          echo "Commands available:"
          echo "  nix build .#neovim     - Build your config"
          echo "  nix run .#default      - Test your config"
          echo "  alejandra .            - Format Nix files"
          echo "  statix check .         - Check for issues"
          echo "  deadnix .              - Find unused code"
          echo ""

          # Set up a test environment
          export NVIM_APPNAME="nvf-test"
          alias nvim-test="${self.packages.${system}.default}/bin/nvim"
        '';
      };
    });

    # Formatter for `nix fmt`
    formatter = forAllSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
