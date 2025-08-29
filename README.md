# Nix + devenv.sh + WordPress #

Quickly bootstrap a self-contained development environment using Nix

## Setup ##

1. Clone your development repo to the appropriate location under `./wordpress` (note: my previous employer's development repos all had `wp-content` at the root so the theme and custom plugins could be in one repo)

2. Run `devenv update` to update Nix packages if needed

3. Run `devenv up` to start all processes. `./wordpress` will automatically geet copied to the correct filesystem location (well, it will soon)

## TODOs ##

* [ ] Backup and restore the database
* [ ] Extra PHP config?
