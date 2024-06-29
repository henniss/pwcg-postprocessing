#! /bin/bash

input=./test/data
output=./test/out
compdir=./components

select component in $(find $compdir -type f -name "*.sh" -printf "%f\n" | sort); do
    if [[ -n $component ]]; then break; fi
done

[[ -z $component ]] && exit 1


rm $output/* 2>/dev/null
cp $input/* $output
find $output -type f -iname "*.mission" -exec "$compdir/$component" '{}' ';';

while IFS= read -rd '' file; do
    echo "diff for $(basename "$file")"
    diff "$input/$(basename "$file")" "$file"
done < <(find $output -type f -iname "*.mission" -print0)

