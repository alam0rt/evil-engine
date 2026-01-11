{
  description = "Evil Engine - Skullmonkeys reimplementation in C with Godot 4";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    godot-headers = {
      url = "github:godotengine/godot-headers";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, godot-headers }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Godot editor
            godot_4
            
            # C toolchain
            gcc
            meson
            ninja
            pkg-config
            
            # Debugging
            gdb
            valgrind
          ];

          shellHook = ''
            export GODOT_HEADERS="${godot-headers}"
            echo "Evil Engine Development Environment"
            echo "===================================="
            echo "Godot: $(godot4 --version 2>/dev/null || echo 'available')"
            echo "GCC: $(gcc --version | head -1)"
            echo "Meson: $(meson --version)"
            echo ""
            echo "Commands:"
            echo "  meson setup build    - Configure build"
            echo "  ninja -C build       - Build GDExtension"
            echo "  godot4 --editor .    - Open in Godot"
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "evil-engine";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [ meson ninja pkg-config ];

          mesonFlags = [
            "-Dgodot_headers=${godot-headers}"
          ];

          installPhase = ''
            mkdir -p $out/lib
            cp libevil_engine*.so $out/lib/ 2>/dev/null || true
            cp libevil_engine*.dylib $out/lib/ 2>/dev/null || true
          '';
        };
      }
    );
}
