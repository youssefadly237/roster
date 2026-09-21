set default-list

# install the package for local use (@local)
install:
    #!/usr/bin/env bash
    set -eu
    name="$(grep '^name =' typst.toml | cut -d'"' -f2)"
    version="$(grep '^version =' typst.toml | cut -d'"' -f2)"
    dest="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/local/$name/$version"
    rm -rf "$dest"
    mkdir -p "$dest"
    cp typst.toml LICENSE "$dest/"
    cp -r src "$dest/"
    echo "installed to $dest"

# format typ
fmt:
    typstyle -i .

# rebuild the gallery SVGs from gallery/shots.typ and optimize them
gallery: install
    TYPST_FEATURES=bundle typst compile --format bundle gallery/shots.typ gallery/
    svgo gallery/*.svg
