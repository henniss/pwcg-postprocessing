# As we rework this...
# basically iterate over every pilot in the pilot code map
# if they're dead, remove them. 
# if they're alive, keep them.
# then make a list of unused codes
# for every pilot in the file, if present, use it, otherwise add them to the map with a new code.
shouldHalt=false

PCM="${PWCGCampaigns}/${campaign}/pilot-code-map.csv"
SP="${PWCGCampaigns}/${campaign}/Personnel/${squadcode}.json"

tempfile=$(mktemp)
tempscript=$(mktemp)

shouldApply () {
# todo squadcode
for v in campaign tac_code_pattern tac_code_color; do 
    [[ -n "${!v}" ]] || { echo "$v unset" ; return 1 ; }
done
[[ -f "$PCM" ]] || { echo "can't find '$PCM'"; return 1 ; }
}


apply () {
set -e

sed -i -e '$a\' "$PCM"

rm -f "$tempfile"
rm -f "$tempscript"

# enumerate pilots.

$ed "$mission" > /dev/null <<EOF
/Flight ${PLAYER_FLIGHT}/
ka
/Name = "Flight/
kb
'a,'bg/LuaScripts.WorldObjects.Planes/n\\
?{?\\
kc\\
/}/\\
kd\\
'c\\
/Name =/\\
.W $tempfile

q
EOF

names="$(cat "$tempfile" | cut -d '"' -f 2)"

declare -A pcm_codes
while IFS=, read a b c
do 
    pcm_codes["$a"]="$c"
done < "$PCM"

while read -r name ; do
    for key in "${!pcm_codes[@]}"; do 
        if [[ "$name" =~ .*$key ]]; then
            code="${pcm_codes[$key]}"
            fullcode="$(printf "$tac_code_pattern" "$code" "$code")"
            printf "%q: %q\n"  "$name" "$fullcode"
            cat >> "$tempscript" <<EOF
/Name = ".*$name";/
?Plane?
ka
n
/}/
kb
n
'a,'bg/TCode \=/s/".*";/"$fullcode";/
'a,'bg/TCodeColor/s/".*";/"$tac_code_color";/
EOF
            continue 2
        fi
    done
    echo "pilot not configured: $name"
    return 1
done <<< "$names"

cat >> "$tempscript" <<EOF
w
q
EOF
echo -e "executing: \n$tempscript"
cat "$tempscript" | $ed "$mission" > /dev/null
}

