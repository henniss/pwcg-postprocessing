function finish {
    # Useful if run via drag-drop to prevent terminal closing.
    read -n 1 -s -p "Done, press any key to exit."
}
trap finish EXIT

mission="$1"
echo "$mission"

script_root="$(cygpath -a "$0")"
script_root="$(dirname "$script_root")"
data="$(realpath ../data)"
durability_file="${data}/durability.csv"

#Model = "graphics\blocks\art_position_big.mgm";
tempfile=$(mktemp)

ed "$mission" >/dev/null <<EOF
g/graphics\\\\blocks/n\\
?{?\\
ka\\
/}/\\
kb\\
'a\\
/Durability/m'a\\
'a\\
/Model/m'a\\
'a+1s/\.mgm.*//\\
'a+1s/.*\\\\//\\
'a+2s/[^[:digit:]]*\([[:digit:]]*\)[^[:digit:]]*/,\1/\\
'a+1,'a+2j\\
'a+1W ${tempfile}\\
kb

Q
EOF

declare -A dmap
echo "loading existing durability file"
while IFS=, read block durability; do
dmap["$block"]="$durability"
done < "$durability_file"

echo "loading new durability values"
while IFS=, read block durability; do
dmap["$block"]="$durability"
done < <(cat "$tempfile" | sort -u)

unset dmap["fake_block"]

exec {df}>"${durability_file}"
for key in ${!dmap[@]} ; do 
  echo "$key"
  echo "${key},${dmap[$key]}">&$df
done

sort -o "$durability_file" "$durability_file"
