BLOCKS="${PWCGInput}/Blocks.json"
head="*Model*graphics\\blocks\\"
tail="mgm\";*"

shouldApply () {
    grep "Durability" -m 1 -q "$mission" && { echo "durability values already present in mission." ; return 1 ; } || return 0
}

apply () {
tempfile=$(mktemp)
replacement=$(mktemp)
cat "$BLOCKS" | jq -r '.blockDefinitions | map([.name, .durability] | join(",")) | join("\n")' > "$tempfile"

echo "got block definitions"

declare -A dmap
while IFS=, read block durability; do
dmap["$block"]="$durability"
done < "$tempfile"

echo "loaded block definitions"

exec {rep}> "$replacement"

i=0
while IFS= read -r line; do
echo "$line" >&${rep}
[[ "$line" =~ graphics\\blocks ]] && { 
    block="${line%.mgm*}" ; 
    block="${block#*graphics\\blocks\\}" ; 
} && {
    echo "Durability = ${dmap[$block]?};" >&${rep} 
}

(( i+= 1 ))
if (( i % 20000 == 0 )) ; then
echo -n "."
fi

done < "$mission"
echo ""

mv "$replacement" "${mission}"
}
