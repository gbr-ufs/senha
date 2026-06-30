{
  description = "Projeto da disciplina 'Sistemas Digitais'.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/master";
  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          emacsSettings = pkgs.writeText "dir-locals.el" ''
            ((nil . ((eval . (with-eval-after-load 'apheleia
                       (add-to-list 'apheleia-formatters
                         '(verible . ("verible-verilog-format" "--inplace" filepath)))))))
             (verilog-mode . ((apheleia-formatter . (verible))
                              (eglot-server-programs . ((verilog-mode . ("verible-verilog-ls"))))))
             (verilog-ts-mode . ((apheleia-formatter . (verible))
                                 (eglot-server-programs . ((verilog-mode . ("verible-verilog-ls")))))))
          '';
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              gtkwave
              iverilog
              verible
            ];
            shellHook = ''
              ln -sf ${emacsSettings} .dir-locals.el
            '';
          };
        }
      );
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
