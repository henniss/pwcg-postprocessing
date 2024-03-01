#!/bin/bash

TEMP=$(mktemp -d)

script_root="$(cygpath -a "$0")"
script_root="$(dirname "$script_root")"
[[ -d "$script_root" ]] && cd "$script_root" || exit 

cp sample-missions/* "$TEMP"
chmod a+w "$TEMP"/*

for m in "$TEMP"/*.mission; do 
    echo "$m"
    ./core.sh "$m"
    echo ""
    echo "-------------"
    echo ""
done