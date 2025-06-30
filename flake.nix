{
  description = "PyOBD - Python OBD-II interface";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit system;
      });
    in
    {
      devShells = forAllSystems ({ pkgs, ... }: {
        default = let
          pythonEnv = pkgs.python3.withPackages (ps: with ps; [
            pyserial
            wxpython
            numpy
            tornado
            pint
            pillow
            six
          ]);
        in pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.git
          ];
          
          shellHook = ''
            echo "PyOBD development environment loaded!"
            echo "Available Python packages: pyserial, wxpython, numpy, tornado, pint, pillow, six"
            echo "Run 'python pyobd.py' to start PyOBD"
          '';
        };
      });
      
      packages = forAllSystems ({ pkgs, ... }: 
        let
          pythonEnv = pkgs.python3.withPackages (ps: with ps; [
            pyserial
            wxpython
            numpy
            tornado
            pint
            pillow
            six
          ]);
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "pyobd";
            version = "0.1.0";
            
            src = ./.;
            
            buildInputs = [ pythonEnv ];
            
            installPhase = ''
              mkdir -p $out/bin $out/share/pyobd
              cp -r * $out/share/pyobd/
              
              cat > $out/bin/pyobd << EOF
              #!/usr/bin/env bash
              cd $out/share/pyobd
              exec ${pythonEnv}/bin/python pyobd.py "\$@"
              EOF
              
              chmod +x $out/bin/pyobd
            '';
            
            meta = with pkgs.lib; {
              description = "Python OBD-II interface";
              homepage = "https://github.com/barracuda-fsh/pyobd";
              license = licenses.gpl2Plus;
              platforms = platforms.unix;
            };
          };
        });
      
      apps = nixpkgs.lib.mapAttrs (system: packages: {
        default = {
          type = "app";
          program = "${packages.default}/bin/pyobd";
        };
      }) self.packages;
    };
}
