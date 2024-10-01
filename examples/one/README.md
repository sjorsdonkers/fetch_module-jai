# Example One

- `main.jai` contains a simple program that depends on external dependencies `Do_A_Thing` (file module) and `Do_Other_Thing` (dir module) which are not in the project yet.
- `first.jai` contains the build script. It uses Modocil to fetch the external dependency then build main.jai in a new workspace.
- >NOTE: `symlink_modocil.jai` is not part of the example and is just a separate script there for convenience.

## Usage

1. Place Modocil.jai in the modules directory (or use the `jai symlink_modocil.jai` script).
1. Build and **fetch** external module (if not already available) with `jai first.jai`.
1. If external dependencies have been updated run `jai first - update` to update/replace the local modules.
