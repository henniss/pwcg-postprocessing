#!/bin/bash

shopt -s nocaseglob
shopt -s nocasematch

TEMP=$(mktemp -d)
[[ -n "$TEMP" ]] || { echo "no temp dir"; exit ; }
cygstart "${TEMP}"

script_root="$(cygpath -a "$0")"
script_root="$(dirname "$script_root")"
[[ -d "$script_root" ]] && cd "$script_root" || exit 

cp sample-missions/* "$TEMP"
chmod a+w "$TEMP"/*

export NO_RESTORE=true

i=0
for m in "$TEMP/"*.mission; do 
    echo "$m"
    ./core.sh "$m"
    echo ""
    echo "-------------"
    echo ""
    ((i+=1))
    if (( i >= ${MU_TEST_MAX:-99})) ; then
        break
    fi
done

if ! [[ "$KEEP_TEST" == true ]] ; then
    rm -r "$TEMP"
fi