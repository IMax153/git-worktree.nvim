{
  description = "Development environment for git-worktree.nvim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Lua runtime
            lua5_1
            luajit

            # Package management
            luarocks

            # Language server
            lua-language-server

            # Formatters
            stylua

            # Linters
            selene

            # Git (required for worktree operations)
            git
          ];

          shellHook = ''
            echo "git-worktree.nvim dev shell"
            echo ""
            echo "Available tools:"
            echo "  lua       - Lua 5.1 interpreter"
            echo "  luajit    - LuaJIT interpreter"
            echo "  luarocks  - Lua package manager"
            echo "  lua-language-server - LSP"
            echo "  stylua    - Lua formatter"
            echo "  selene    - Lua linter"
            echo ""
          '';
        };
      }
    );
}
