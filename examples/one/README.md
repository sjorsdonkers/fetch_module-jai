# Example One

- `main.jai` contains a simple program that depends on external dependencies `Do_A_Thing` (file module) and `Do_Other_Thing` (dir module) which are not in the project yet.
- `first.jai` contains the build script. It uses Plutus to fetch the external dependency then build main.jai in a new workspace.

## Usage

1. Place Plutus.jai in the modules directory (or use the `create_symlink` script).
1. Build and **fetch** external module (if not already available) with `jai first.jai`.
1. If external dependencies have been updated run `jai first - update` to update/replace the local modules.
